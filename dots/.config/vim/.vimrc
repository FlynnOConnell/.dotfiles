" General settings
set so=20  " Keep 20 lines above/below cursor
set nu
set relativenumber
set sneak
set clipboard+=unnamed
set ignorecase
set smartcase
set scrolloff=5
set wildignore+=*/target/*,*/.idea/*,*/.git/*,*/.svn/*,*/.hg/*,*/build/*

" Mappings
let mapleader=" "
imap kj <Esc>

" Plugins
set surround
set commentary
set NERDTree
set highlightedyank

" Window / Split Management
noremap <C-L> <C-W><C-L>
noremap <C-H> <C-W><C-H>
noremap <C-K> <C-W><C-K>
noremap <C-J> <C-W><C-J>

" Mappings
nnoremap \ :NERDTree<CR>
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

function! Praise(name)
  echo a:name . " is good"
endfunction

nmap <leader>; :call Praise("Vim")<CR>
