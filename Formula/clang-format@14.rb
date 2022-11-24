class ClangFormatAT14 < Formula
  desc "Formatting tools for C, C++, Obj-C, Java, JavaScript, TypeScript"
  homepage "https://clang.llvm.org/docs/ClangFormat.html"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  license "Apache-2.0"
  version_scheme 1
  head "https://github.com/llvm/llvm-project.git", branch: "main"

  stable do
    url "https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/llvm-14.0.6.src.tar.xz"
    sha256 "050922ecaaca5781fdf6631ea92bc715183f202f9d2f15147226f023414f619a"

    resource "clang" do
      url "https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/clang-14.0.6.src.tar.xz"
      sha256 "2b5847b6a63118b9efe5c85548363c81ffe096b66c3b3675e953e26342ae4031"
    end
  end

  livecheck do
    url :stable
    strategy :github_latest
    regex(%r{href=.*?/tag/llvmorg[._-]v?(\d+(?:\.\d+)+)}i)
  end

  bottle do
    root_url "https://github.com/obsproject/homebrew-tools/releases/download/clang-format@14-14.0.6"
    sha256 cellar: :any_skip_relocation, monterey:     "6d6e3094134d6645285a8ed795c2372cbdc9b60d062a672b2c7e9fedadcb33b4"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "97073b1a88f7a78ef5c7ea876fa749eed17ddd9bfb6276981bf9437ae6201612"
  end

  depends_on "cmake" => :build

  uses_from_macos "ncurses"
  uses_from_macos "zlib"

  on_linux do
    keg_only "it conflicts with llvm"
  end

  def install
    llvmpath = if build.head?
      ln_s buildpath/"clang", buildpath/"llvm/tools/clang"

      buildpath/"llvm"
    else
      resource("clang").stage do |r|
        (buildpath/"llvm-#{version}.src/tools/clang").install Pathname("clang-#{r.version}.src").children
      end

      buildpath/"llvm-#{version}.src"
    end

    system "cmake", "-S", llvmpath, "-B", "build",
                    "-DLLVM_EXTERNAL_PROJECTS=clang",
                    "-DLLVM_ENABLE_LIBXML2=OFF",
                    "-DLLVM_INCLUDE_BENCHMARKS=OFF",
                    "-DLLVM_INCLUDE_TESTS=OFF",
                    *std_cmake_args
    system "cmake", "--build", "build", "--target", "clang-format"

    git_clang_format = llvmpath/"tools/clang/tools/clang-format/git-clang-format"

    inreplace git_clang_format, %r{^#!/usr/bin/env python$}, "#!/usr/bin/env python3"
    inreplace git_clang_format, /clang-format/, "clang-format-14"
    bin.install "build/bin/clang-format" => "clang-format-14"
    bin.install git_clang_format => "git-clang-format-14"
    (share/"clang").install llvmpath.glob("tools/clang/tools/clang-format/clang-format*")
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
