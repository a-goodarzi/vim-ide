let mapleader = ","
set number relativenumber
set tabstop=4 shiftwidth=4 expandtab
set ignorecase smartcase
set nowrap
inoremap jk <Esc>
nnoremap <leader>s :w<CR>
nnoremap <leader>n :NERDTreeToggle<CR>
nnoremap <C-p> :Files<CR>
nnoremap <leader>rg :Rg<CR>
Plug 'preservim/nerdtree'
Plug 'junegunn/fzf.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
