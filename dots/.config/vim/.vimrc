" General settings
set so=20  " Keep 20 lines above/below cursor
set nu
set relativenumber
set clipboard+=unnamed
set ignorecase
set smartcase
set scrolloff=5

" Mappings
let mapleader=" "
imap kj <Esc>

" Plugins
set surround
set commentary

nnoremap \ :NERDTree<CR>

" Window / Split Management
noremap <C-L> <C-W><C-L>
noremap <C-H> <C-W><C-H>
noremap <C-K> <C-W><C-K>
noremap <C-J> <C-W><C-J>

vnoremap  <leader>y  "+y
nnoremap  <leader>Y  "+yg_
nnoremap  <leader>y  "+y
nnoremap  <leader>yy  "+yy

" " Paste from clipboard
nnoremap <leader>p "+p
nnoremap <leader>P "+P
vnoremap <leader>p "+p
vnoremap <leader>P "+P


" Mappings
map n nzzzv
map N Nzzzv
map j jzz
map k kzz

" Keep selection after visual indent
vnoremap < <gv
vnoremap > >gv

" Control binds
vnoremap <C-j> <ESC>
map <C-d> <C-d>zz
map <C-u> <C-u>zz

" Tabs
map <C-1> 1gt
map <C-2> 2gt
map <C-3> 3gt
map <C-4> 4gt
map <C-5> 5gt
map <C-6> 6gt
map <C-7> 7gt
