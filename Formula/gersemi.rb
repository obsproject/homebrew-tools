class Gersemi < Formula
  include Language::Python::Virtualenv

  desc "Formatter to make your CMake code the real treasure"
  homepage "https://github.com/BlankSpruce/gersemi"
  url "https://files.pythonhosted.org/packages/70/e7/a6ba718877a95fbd91b3249c76f2e2a5e399b7e3fb2333f34363c12ef3b7/gersemi-0.15.0.tar.gz"
  sha256 "b2e40e38fc46aff8e15331f9331e513b45d615087e4616c92a2a792d59c87c09"

  head "https://github.com/BlankSpruce/gersemi.git", branch: "master"

  bottle do
    root_url "https://github.com/obsproject/homebrew-tools/releases/download/gersemi-0.15.0"
    sha256 cellar: :any,                 arm64_sonoma: "7e19d984ea351b561c9a7c7591b47d3886dbb6c65b8678ff14a39b40f5ab183b"
    sha256 cellar: :any,                 ventura:      "3adbe8664f4b59e8129498ce01c76641342cdb86e1f9e96acbb9a2b02fb856b5"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "7bef37946f089c897c9c104c18250520eb5a5245b38ad435a500fe97cc18f0f1"
  end

  depends_on "libyaml"
  depends_on "python@3.12"

  resource "appdirs" do
    url "https://files.pythonhosted.org/packages/d7/d8/05696357e0311f5b5c316d7b95f46c669dd9c15aaeecbb48c7d0aeb88c40/appdirs-1.4.4.tar.gz"
    sha256 "7d5d0167b2b1ba821647616af46a749d1c653740dd0d2415100fe26e27afdf41"
  end

  resource "dataclasses" do
    url "https://files.pythonhosted.org/packages/59/e4/2f921edfdf1493bdc07b914cbea43bc334996df4841a34523baf73d1fb4f/dataclasses-0.6.tar.gz"
    sha256 "6988bd2b895eef432d562370bb707d540f32f7360ab13da45340101bc2307d84"
  end

  resource "lark" do
    url "https://files.pythonhosted.org/packages/2c/e1/804b6196b3fbdd0f8ba785fc62837b034782a891d6f663eea2f30ca23cfa/lark-1.1.9.tar.gz"
    sha256 "15fa5236490824c2c4aba0e22d2d6d823575dcaf4cdd1848e34b6ad836240fba"
  end

  resource "PyYAML" do
    url "https://files.pythonhosted.org/packages/cd/e5/af35f7ea75cf72f2cd079c95ee16797de7cd71f29ea7c68ae5ce7be1eda0/PyYAML-6.0.1.tar.gz"
    sha256 "bfdf460b1736c775f2ba9f6a92bca30bc2095067b8a9d77876d1fad6cc3b4a43"
  end

  def install
    virtualenv_install_with_resources
  end
end
