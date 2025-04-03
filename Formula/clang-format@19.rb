class ClangFormatAT19 < Formula
  desc "Formatting tools for C, C++, Obj-C, Java, JavaScript, TypeScript"
  homepage "https://clang.llvm.org/docs/ClangFormat.html"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.1/llvm-19.1.1.src.tar.xz"
  sha256 "15a7c77f9c39444d9dd6756b75b9a70129dcbd1e340724a6e45b3b488f55bc4b"
  license "Apache-2.0" => { with: "LLVM-exception" }
  revision 1
  version_scheme 1
  head "https://github.com/llvm/llvm-project.git", branch: "main"

  livecheck do
    url :stable
    regex(/llvmorg[._-]v?(\d+(?:\.\d+)+)/i)
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/obsproject/homebrew-tools/releases/download/clang-format@19-19.1.1"
    sha256 cellar: :any_skip_relocation, arm64_sonoma: "b01ec303053e53d181a47c54143995e6daa5109d392a9bff7fd8f9b4471291ef"
    sha256 cellar: :any_skip_relocation, ventura:      "e1bb7cec0e1c4b9e8bf429d2a1aa1a1b534030f60f1201798db46775d99ff4a9"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "88f419613cec12f8928c8314c88cdf9d919ce00d717524fb4631015f4bae96aa"
  end

  depends_on "cmake" => :build
  depends_on "ninja" => :build

  uses_from_macos "libxml2"
  uses_from_macos "ncurses"
  uses_from_macos "python", since: :catalina
  uses_from_macos "zlib"

  on_linux do
    keg_only "it conflicts with llvm"
  end

  resource "clang" do
    url "https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.1/clang-19.1.1.src.tar.xz"
    sha256 "73881ccf065c35ca67752c2d4b6dd0157140330eef318fb80f1a62681145cf7c"
  end

  resource "cmake" do
    url "https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.1/cmake-19.1.1.src.tar.xz"
    sha256 "92a016ecfe46ad7c18db6425a018c2c6ee126b9d0e5513d6fad989fee6648ffa"
  end

  resource "third-party" do
    url "https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.1/third-party-19.1.1.src.tar.xz"
    sha256 "39dec41a0a4d39af6428a58ddbd5c3e5c3ae4f6175e3655480909559cba86cb7"
  end

  def install
    odie "clang resource needs to be updated" if build.stable? && version != resource("clang").version
    odie "cmake resource needs to be updated" if build.stable? && version != resource("cmake").version
    odie "third-party resource needs to be updated" if build.stable? && version != resource("third-party").version

    llvmpath = if build.head?
      ln_s buildpath/"clang", buildpath/"llvm/tools/clang"

      buildpath/"llvm"
    else
      (buildpath/"src").install buildpath.children
      (buildpath/"src/tools/clang").install resource("clang")
      (buildpath/"cmake").install resource("cmake")
      (buildpath/"third-party").install resource("third-party")

      buildpath/"src"
    end

    system "cmake", "-G", "Ninja", "-S", llvmpath, "-B", "build",
                    "-DLLVM_EXTERNAL_PROJECTS=clang",
                    "-DLLVM_INCLUDE_BENCHMARKS=OFF",
                    "-DLLVM_INCLUDE_TESTS=OFF",
                    *std_cmake_args
    system "cmake", "--build", "build", "--target", "clang-format"

    git_clang_format = llvmpath/"tools/clang/tools/clang-format/git-clang-format"
    inreplace git_clang_format, /clang-format/, "clang-format-19"

    bin.install "build/bin/clang-format" => "clang-format-19"
    bin.install git_clang_format => "git-clang-format-19"
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
        shell_output("#{bin}/clang-format-19 -style=Google test.c")

    ENV.prepend_path "PATH", bin
    assert_match "test.c", shell_output("git clang-format-19", 1)
  end
end
