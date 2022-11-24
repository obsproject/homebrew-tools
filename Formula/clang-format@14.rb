class ClangFormatAT14 < Formula
  desc "Formatting tools for C, C++, Obj-C, Java, JavaScript, TypeScript"
  homepage "https://clang.llvm.org/docs/ClangFormat.html"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/llvm-14.0.6.src.tar.xz"
  sha256 "050922ecaaca5781fdf6631ea92bc715183f202f9d2f15147226f023414f619a"
  license "Apache-2.0"
  version_scheme 1

  livecheck do
    url :stable
    strategy :github_latest
    regex(%r{href=.*?/tag/llvmorg[._-]v?(\d+(?:\.\d+)+)}i)
  end

  bottle do
    root_url "https://github.com/obsproject/homebrew-tools/releases/download/clang-format@14-14.0.6"
    rebuild 1
    sha256 cellar: :any_skip_relocation, monterey:     "2f7f29ba30ab9c29408ed2a2cafd41ea9efe4fccaf8c9fff73787808ae801c65"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "78adc035042ad29c9b9f58975f255ee87ea5b4381e18b3e708f0f997b46adba2"
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
    url "https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/clang-14.0.6.src.tar.xz"
    sha256 "2b5847b6a63118b9efe5c85548363c81ffe096b66c3b3675e953e26342ae4031"
  end

  def install
    resource("clang").stage do |r|
      (buildpath/"llvm-#{version}.src/tools/clang").install Pathname("clang-#{r.version}.src").children
    end

    llvmpath = buildpath/"llvm-#{version}.src"

    system "cmake", "-G", "Ninja", "-S", llvmpath, "-B", "build",
                    "-DLLVM_EXTERNAL_PROJECTS=clang",
                    "-DLLVM_INCLUDE_BENCHMARKS=OFF",
                    "-DLLVM_INCLUDE_TESTS=OFF",
                    *std_cmake_args
    system "cmake", "--build", "build", "--target", "clang-format"

    git_clang_format = llvmpath/"tools/clang/tools/clang-format/git-clang-format"

    inreplace git_clang_format, %r{^#!/usr/bin/env python$}, "#!/usr/bin/env python3"
    inreplace git_clang_format, /clang-format/, "clang-format-14"
    bin.install "build/bin/clang-format" => "clang-format-14"
    bin.install git_clang_format => "git-clang-format-14"
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
        shell_output("#{bin}/clang-format-14 -style=Google test.c")

    ENV.prepend_path "PATH", bin
    assert_match "test.c", shell_output("git clang-format-14")
  end
end
