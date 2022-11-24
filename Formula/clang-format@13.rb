class ClangFormatAT13 < Formula
  desc "Formatting tools for C, C++, Obj-C, Java, JavaScript, TypeScript"
  homepage "https://clang.llvm.org/docs/ClangFormat.html"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.1/llvm-13.0.1.src.tar.xz"
  sha256 "ec6b80d82c384acad2dc192903a6cf2cdbaffb889b84bfb98da9d71e630fc834"
  license "Apache-2.0"
  version_scheme 1

  livecheck do
    url :stable
    strategy :github_latest
    regex(%r{href=.*?/tag/llvmorg[._-]v?(\d+(?:\.\d+)+)}i)
  end

  bottle do
    root_url "https://github.com/obsproject/homebrew-tools/releases/download/clang-format@13-13.0.1"
    rebuild 1
    sha256 cellar: :any_skip_relocation, monterey:     "9bb554a387c5a4733b23b1e851c89af9e8e1f55df63064fab521a6dfc17be4d0"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "03dd3dd857a628b37d30a34bdcca2ab08d9f971c6a9635057f12165e33366c31"
  end

  depends_on "cmake" => :build
  depends_on "ninja" => :build

  uses_from_macos "libxml2"
  uses_from_macos "ncurses"
  uses_from_macos "zlib"

  on_linux do
    keg_only "it conflicts with llvm"
  end

  resource "clang" do
    url "https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.1/clang-13.0.1.src.tar.xz"
    sha256 "787a9e2d99f5c8720aa1773e4be009461cd30d3bd40fdd24591e473467c917c9"
  end

  def install
    (buildpath/"tools/clang").install resource("clang")

    system "cmake", "-G", "Ninja", "-S", buildpath, "-B", "build",
                    "-DLLVM_EXTERNAL_PROJECTS=clang",
                    "-DLLVM_INCLUDE_BENCHMARKS=OFF",
                    "-DLLVM_INCLUDE_TESTS=OFF",
                    *std_cmake_args
    system "cmake", "--build", "build", "--target", "clang-format"

    bin.install buildpath/"build/bin/clang-format" => "clang-format-13"
    bin.install buildpath/"tools/clang/tools/clang-format/git-clang-format" => "git-clang-format-13"
  end

  test do
    # NB: below C code is messily formatted on purpose.
    (testpath/"test.c").write <<~EOS
      int         main(char *args) { \n   \t printf("hello"); }
    EOS

    assert_equal "int main(char *args) { printf(\"hello\"); }\n",
        shell_output("#{bin}/clang-format-13 -style=Google test.c")
  end
end
