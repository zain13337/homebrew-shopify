# frozen_string_literal: true

require "formula"
require "language/node"
require "fileutils"

class ShopifyCli < Formula
  desc "A CLI tool to build for the Shopify platform"
  homepage "https://github.com/shopify/cli#readme"
  url "https://registry.npmjs.org/@shopify/cli/-/cli-3.24.1.tgz"
  sha256 "ec10a89aff67475aa057a70ff72566a08e01d2431410a3668b81f3a1f12cfb8b"
  license "MIT"
  depends_on "node"
  depends_on "ruby"
  depends_on "git"

  resource "cli-theme-commands" do
    url "https://registry.npmjs.org/@shopify/theme/-/theme-3.24.1.tgz"
    sha256 "29dff5f3a08391bd2ba655ea7d53d2a75fda060b89173f7f2efb0a73312460f4"
  end

  livecheck do
    url :stable
  end

  def install
    existing_cli_path = `which shopify`
    unless existing_cli_path.empty? || existing_cli_path.include?("homebrew")
      opoo <<~WARNING
      We've detected an installation of the Shopify CLI at #{existing_cli_path} that's not managed by Homebrew.

      Please ensure that the Homebrew line in your shell configuration is at the bottom so that Homebrew-managed
      tools take precedence.
      WARNING
    end

    system "npm", "install", *Language::Node.std_npm_install_args(libexec)

    original_executable_path = "#{libexec}/bin/shopify"
    executable_path = "#{original_executable_path}"
    FileUtils.move(original_executable_path, "#{executable_path}-original")
    executable_content = <<~SCRIPT
      #!/usr/bin/env #{Formula["node"].opt_bin}/node

      process.env.SHOPIFY_RUBY_BINDIR = "#{Formula["ruby"].opt_bin}"
      process.env.SHOPIFY_HOMEBREW_FORMULA = "shopify-cli"

      import("./shopify-original");
    SCRIPT
    File.write executable_path, executable_content
    FileUtils.chmod("+x", executable_path)

    bin.install_symlink executable_path

    resource("cli-theme-commands").stage {
      system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    }
  end

  def post_install
    message = <<~POSTINSTALL_MESSAGE
      Congratulations, you've successfully installed Shopify CLI 3!

      Global installations of Shopify CLI 3 should only be used to work on Shopify
      themes. To learn about the changes to theme workflows in this version, refer
      to https://shopify.dev/themes/tools/cli/migrate#workflow-changes

      If you want to keep using Shopify CLI 2, then you can install it again using
      `brew install shopify-cli@2` and run commands using the `shopify2` program
      name (for example, `shopify2 theme push` and `shopify2 extension push`).
      Note however that Shopify CLI 2 will be sunset in H1 2023 - specific date
      to be announced in Q4 2022.
    POSTINSTALL_MESSAGE
    message.each_line { |line| ohai line.chomp }
  end
end
