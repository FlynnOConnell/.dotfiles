set surround
set commentary
set relativenumber
set number
set incsearch
set showmode

"python auto-indent
filetype plugin indent on
set smartindent
" show existing tab with 4 spaces width
set tabstop=4
" when indenting with '>', use 4 spaces width
set shiftwidth=4
" on pressing tab, insert 4 spaces
set expandtab
"methods of classes are folded, but internals arent
set foldnestmax=2
set foldmethod=indent

set clipboard+=unnamed
set clipboard+=ideaputnnoremap \e :e ~/.ideavimrc<CR>
nnoremap \r :action IdeaVim.ReloadVimRc.reload<CR>

nnoremap <cr> zz
nnoremap <c-d> <c-d>zz
nnoremap <c-u> <c-u>zz
xnoremap <leader>p <+p>
nnoremap <leader>y <+y>
nnoremap <leader>dd "_dd
imap kj <ESC>

"move between splits"
nmap <c-h> <c-w>h
nmap <c-l> <c-w>l

nmap j jzz
nmap k kzz
nnoremap n nzz
nnoremap n nzz
nnoremap N Nzz
"keep selection after indent/outdent"
vnoremap < <gv
vnoremap > >gv

" Chezmoi apply
autocmd BufWritePost ~/.local/share/chezmoi/* ! chezmoi apply --source-path "%"
