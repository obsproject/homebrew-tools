class ClangFormatAT22 < Formula
  desc "Formatting tools for C, C++, Obj-C, Java, JavaScript, TypeScript"
  homepage "https://clang.llvm.org/docs/ClangFormat.html"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-22.1.3/llvm-project-22.1.3.src.tar.xz"
  sha256 "2488c33a959eafba1c44f253e5bbe7ac958eb53fa626298a3a5f4b87373767cd"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  license "Apache-2.0" => { with: "LLVM-exception" }
  version_scheme 1
  head "https://github.com/llvm/llvm-project.git", branch: "main"

  livecheck do
    url :stable
    regex(/llvmorg[._-]v?(\d+(?:\.\d+)+)/i)
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/obsproject/homebrew-tools/releases/download/clang-format@22-22.1.3"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:   "bc9e58d81979c87b283696c1e53f4c34d96086f43a9c8c6e77723f6da5acb6cb"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "88da3851bc6a02a1f0738f1bc7d44a4f6c4b4656f9c56b3bb6106b43c5a533ec"
    sha256 cellar: :any,                 x86_64_linux:  "cbf3027ea9d20db4ceeb811ea001e757adf8757533171a9d696d5c2eb812c088"
  end

  depends_on "cmake" => :build

  uses_from_macos "python"

  on_linux do
    keg_only "it conflicts with llvm"
  end

  def install
    system "cmake", "-S", "llvm", "-B", "build",
                    "-DLLVM_ENABLE_PROJECTS=clang",
                    "-DLLVM_INCLUDE_BENCHMARKS=OFF",
                    *std_cmake_args
    system "cmake", "--build", "build", "--target", "clang-format"

    git_clang_format = buildpath/"clang/tools/clang-format/git-clang-format"
    inreplace git_clang_format, /clang-format/, "clang-format-22"

    bin.install "build/bin/clang-format" => "clang-format-22"
    bin.install git_clang_format => "git-clang-format-22"
  end

  test do
    system "git", "init"
    system "git", "commit", "--allow-empty", "-m", "initial commit", "--quiet"

    # NB: below C code is messily formatted on purpose.
    (testpath/"test.c").write <<~C
      int         main(char *args) { \n   \t printf("hello"); }
    C
    system "git", "add", "test.c"

    assert_equal <<~C, shell_output("#{bin}/clang-format-22 -style=Google test.c")
      int main(char* args) { printf("hello"); }
    C

    ENV.prepend_path "PATH", bin
    assert_match "test.c", shell_output("git clang-format-22", 1)
  end
end
