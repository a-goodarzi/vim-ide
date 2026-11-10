# Homebrew formula for vim-ide (untested template: copy it into a tap, e.g. homebrew-tap/Formula/vim-ide.rb).
#   brew tap a-goodarzi/tap && brew install vim-ide
class VimIde < Formula
  desc "VS Code-style IDE built on Neovim (activity bar, tabs, Git, Claude Code, tmux friendly)"
  homepage "https://github.com/a-goodarzi/vim-ide"
  url "https://github.com/a-goodarzi/vim-ide.git", tag: "v0.21.0"
  license "GPL-3.0-or-later"
  head "https://github.com/a-goodarzi/vim-ide.git", branch: "main"

  depends_on "neovim"
  depends_on "git"
  depends_on "make"
  depends_on "node"
  depends_on "ripgrep"
  depends_on "tree-sitter-cli"

  def install
    libexec.install Dir["*"]
    (bin/"ide").write <<~EOS
      #!/usr/bin/env bash
      # Links the packaged config as ~/.config/nvim-ide on first use, then starts the launcher.
      cfg="${XDG_CONFIG_HOME:-$HOME/.config}/nvim-ide"
      [ -e "$cfg" ] || { mkdir -p "$(dirname "$cfg")"; ln -s "#{opt_libexec}/nvim-ide/assets/template" "$cfg"; }
      export NVIM_APPNAME=nvim-ide
      exec "#{opt_libexec}/nvim-ide/assets/template/extras/ide" "$@"
    EOS
  end

  def caveats
    <<~EOS
      Start the IDE with `ide`. The first start installs the plugins (needs network).
      Your own ~/.config/nvim is not touched: the config lives in ~/.config/nvim-ide.
      Use a Nerd Font in your terminal for the icons.
    EOS
  end

  test do
    assert_match "ide", shell_output("#{bin}/ide --help")
  end
end
