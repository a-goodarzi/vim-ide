# Roadmap

Ideas noted for later, in the order they were listed. Items 5 to 13 shipped in 0.5.0 to 0.13.0 (see CHANGELOG.md).

## Menus and discoverability
- **Smarter palette:** recent entries first, a "Run task" and "Open project" group, git actions, an entry for every theme.
- **Context menus:** a right-click menu in the editor and the Explorer (the tab bar already has one).
- **Built-in tour:** a five-step first-run walkthrough of the activity bar, tabs and palette.

## Design and polish
- **Check all themes:** screenshot every theme and compare contrast, especially the tab bar on light themes.
- **Tab style option:** slanted (current), rounded or flat, chosen in Settings.
- **Small known issues:** the Plugins icon does not toggle off like the other views; the minimap overlaps pages in `ide settings` mode.
- **Accessibility:** a high-contrast theme and an option to rely less on icons.

## Project and release
- **CI and releases:** GitHub Actions for smoke tests, lint, shellcheck and `bash -n`; attach the two `.skill` files to each release. (macOS testing was skipped on request.)
- **Contribution docs:** CONTRIBUTING.md, an issue template asking for `nvim --version`, terminal and `:checkhealth`, and a guide to adding a language, theme or feature.
- **Install options:** a one-line installer with a checksum, a Homebrew formula, a Docker image to try it without installing.
- **Demo GIF** in the README.
- **Update safety:** `ide update` shows the lockfile changes and can roll back.

## Known gaps in what shipped
- Debugging has never been run end to end here (Mason's `debugpy` was half-installed); the F5 path only warns.
- Tabs cannot be dragged with the mouse (a terminal tab line has no drag events); use the menu or Alt-< / Alt->.
- Remote support is shells, scp editing and container shells, not a remote-IDE client.
- Explorer drag and drop is not possible in a terminal; neo-tree's cut / copy / paste covers bulk moves.
