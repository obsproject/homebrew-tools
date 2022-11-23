class ClangFormatAT13 < Formula
  desc "Formatting tools for C, C++, Obj-C, Java, JavaScript, TypeScript"
  homepage "https://clang.llvm.org/docs/ClangFormat.html"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  license "Apache-2.0"
  version_scheme 1
  head "https://github.com/llvm/llvm-project.git", branch: "main"

  stable do
    url "https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.1/llvm-13.0.1.src.tar.xz"
    sha256 "ec6b80d82c384acad2dc192903a6cf2cdbaffb889b84bfb98da9d71e630fc834"

    resource "clang" do
      url "https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.1/clang-13.0.1.src.tar.xz"
      sha256 "787a9e2d99f5c8720aa1773e4be009461cd30d3bd40fdd24591e473467c917c9"
    end
  end

  livecheck do
    url :stable
    strategy :github_latest
    regex(%r{href=.*?/tag/llvmorg[._-]v?(\d+(?:\.\d+)+)}i)
  end

  bottle do
    root_url "https://github.com/PatTheMav/homebrew-custom/releases/download/clang-format@13-13.0.1"
    sha256 cellar: :any_skip_relocation, big_sur:      "4690529113bad75f7bb6d01c85df76826cb7dca93066ba6ef52793a7d5caa49e"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "8704ba1657e5832ad5e06ed4e966b0591e41367e4cccec7b0b70cc2e0d3cd65d"
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

  def install
    if build.head?
      ln_s buildpath/"clang", buildpath/"llvm/tools/clang"
    else
      (buildpath/"tools/clang").install resource("clang")
    end

    llvmpath = build.head? ? buildpath/"llvm" : buildpath

    mkdir llvmpath/"build" do
      args = std_cmake_args
      args << "-DLLVM_EXTERNAL_PROJECTS=\"clang\""
      args << ".."
      system "cmake", "-G", "Ninja", *args
      system "ninja", "clang-format"
    end

    bin.install llvmpath/"build/bin/clang-format" => "clang-format-13"
    bin.install llvmpath/"tools/clang/tools/clang-format/git-clang-format" => "git-clang-format-13"
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
