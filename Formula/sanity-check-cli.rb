class SanityCheckCli < Formula
  desc "Lint, format, and sanity-check your scripts, configs, and Docker/Terraform files"
  homepage "https://github.com/raymonepping/sanity_check_cli"
  url "https://github.com/raymonepping/homebrew-sanity-check-cli/archive/refs/tags/v1.3.4.tar.gz"
  sha256 "b264da00c8a3a6547e36ab8796a390b61f9d690e422e159077b8a9dcae112840"
  license "MIT"
  version "1.3.4"

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
