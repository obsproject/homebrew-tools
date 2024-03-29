class ClangFormatAT15 < Formula
  desc "Formatting tools for C, C++, Obj-C, Java, JavaScript, TypeScript"
  homepage "https://clang.llvm.org/docs/ClangFormat.html"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.6/llvm-15.0.6.src.tar.xz"
  sha256 "0b32199401f27e2e0353846a8c5fbadd77beca2570654fb9ef7ac9b7f26967e3"
  license "Apache-2.0"
  version_scheme 1

  livecheck do
    url :stable
    strategy :github_latest
    regex(%r{href=.*?/tag/llvmorg[._-]v?(\d+(?:\.\d+)+)}i)
  end

  bottle do
    root_url "https://github.com/obsproject/homebrew-tools/releases/download/clang-format@15-15.0.6"
    sha256 cellar: :any_skip_relocation, monterey:     "8b866776bade68cfe70083064eac4707d806083d553314afb7f16112a8a5fcf6"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "0c8aa2d91a1700dbdc4b0f8f4b96c41b14b18380e726e4141bda098df947dc82"
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
    url "https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.6/clang-15.0.6.src.tar.xz"
    sha256 "10119ae195f1b4f979fe42e67b781e175b0c0d4e982fd6a2f44c4aa7fc925233"
  end

  resource "cmake" do
    url "https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.6/cmake-15.0.6.src.tar.xz"
    sha256 "7613aeeaba9b8b12b35224044bc349b5fa45525919625057fa54dc882dcb4c86"
  end

  def install
    (buildpath/"src").install buildpath.children
    (buildpath/"src/tools/clang").install resource("clang")

    (buildpath/"cmake").install resource("cmake")

    llvmpath = buildpath/"src"

    system "cmake", "-G", "Ninja", "-S", llvmpath, "-B", "build",
                    "-DLLVM_EXTERNAL_PROJECTS=clang",
                    "-DLLVM_INCLUDE_BENCHMARKS=OFF",
                    "-DLLVM_INCLUDE_TESTS=OFF",
                    *std_cmake_args
    system "cmake", "--build", "build", "--target", "clang-format"

    git_clang_format = llvmpath/"tools/clang/tools/clang-format/git-clang-format"
    inreplace git_clang_format, /clang-format/, "clang-format-15"

    bin.install "build/bin/clang-format" => "clang-format-15"
    bin.install git_clang_format => "git-clang-format-15"
  end

  test do
    system "git", "init"
    system "git", "commit", "--allow-empty", "-m", "initial commit", "--quiet"

    # NB: below C code is messily formatted on purpose.
    (testpath/"test.c").write <<~EOS
      int         main(char *args) { \n   \t printf("hello"); }
    EOS
    system "git", "add", "test.c"

    assert_equal "int main(char *args) { printf(\"hello\"); }\n",
        shell_output("#{bin}/clang-format-15 -style=Google test.c")

    ENV.prepend_path "PATH", bin
    assert_match "test.c", shell_output("git clang-format-15", 1)
  end
end
