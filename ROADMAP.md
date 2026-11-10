# Roadmap

Ideas noted for later. Everything else that was on this list has shipped (see CHANGELOG.md).

## Not done yet
- **CI:** GitHub Actions for the smoke tests, lint, shellcheck, `bash -n` and the theme contrast check on every push; attach the two `.skill` files to each release. (macOS testing was skipped on request.)
- **Accessibility:** a high-contrast theme and an option to rely less on icons.
- **Homebrew:** the formula in `packaging/homebrew/` is an untested template; it needs a tap and a test on a Mac.
- **Theme polish:** the contrast check passes, but only a handful of themes have been looked at by eye.

## Known gaps in what shipped
- Debugging has never been run end to end here (Mason's `debugpy` was half-installed); the F5 path only warns.
- Tabs cannot be dragged with the mouse (a terminal tab line has no drag events); use the menu or Alt-< / Alt->.
- Remote support is shells, scp editing and container shells, not a remote-IDE client.
- Explorer drag and drop is not possible in a terminal; neo-tree's cut / copy / paste covers bulk moves.
- The `ayu` theme has faint line numbers (its own design; contrast 1.2).
