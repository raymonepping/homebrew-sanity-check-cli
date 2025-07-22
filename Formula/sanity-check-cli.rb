class SanityCheckCli < Formula
  desc "Lint, format, and sanity-check your scripts, configs, and Docker/Terraform files"
  homepage "https://github.com/raymonepping/sanity_check_cli"
  url "https://github.com/raymonepping/homebrew-sanity-check-cli/archive/refs/tags/v1.1.4.tar.gz"
  sha256 "4e8a782d11c4602ba0bf21083164fa4e5c95d61842e1e573295d4cc190046c3f"
  license "MIT"
  version "1.1.4"

  depends_on "bash"
  depends_on "jq"

  def install
    bin.install "bin/sanity_check" => "sanity_check"
    share.install Dir["lib"], Dir["tpl"]
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
