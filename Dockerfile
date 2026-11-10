# Try vim-ide without installing anything on your machine:
#   docker build -t vim-ide .
#   docker run --rm -it -v "$PWD":/work vim-ide            # edits the folder you run it from
# The terminal needs a Nerd Font for the icons (the container has no display, your terminal draws them).
FROM fedora:latest
RUN dnf install -y neovim git make gcc gcc-c++ ripgrep nodejs npm tree-sitter-cli python3 unzip tar gzip which tmux \
    && dnf clean all
RUN useradd -m ide
USER ide
WORKDIR /home/ide
COPY --chown=ide:ide . /home/ide/vim-ide
ENV TERM=xterm-256color COLORTERM=truecolor PATH=/home/ide/.local/bin:$PATH
# Plugins are installed at build time; language servers and formatters (Mason) install on first use. Add `--skip-mason` removal below
# to bake them in as well (the image gets much larger).
RUN bash /home/ide/vim-ide/nvim-ide/scripts/dev.sh --skip-mason --skip-tmux --no-run
WORKDIR /work
ENTRYPOINT ["ide"]
