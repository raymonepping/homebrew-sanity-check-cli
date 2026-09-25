class SanityCheckCli < Formula
  desc "Lint, format, and sanity-check your scripts, configs, and Docker/Terraform files"
  homepage "https://github.com/raymonepping/sanity_check_cli"
  url "https://github.com/raymonepping/homebrew-sanity-check-cli/archive/refs/tags/v1.3.5.tar.gz"
  sha256 "7a1cea0a5bcfc6e1bb68c708b9371e017d95d352378e208713992964bc439176"
  license "MIT"
  version "1.3.5"

  depends_on "bash"
  depends_on "jq"

  def install
    bin.install "bin/sanity_check" => "sanity_check"
    pkgshare.install %w[lib tpl]
  end

  def caveats
    <<~EOS
      To get started, run:
        sanity_check --help

      Example usage:
        sanity_check main.py
        sanity_check Dockerfile --lint
        sanity_check --report ./src

      Happy linting!
    EOS
  end

  test do
    assert_match "sanity_check", shell_output("#{bin}/sanity_check --help")
  end
end
