" Mappings
let mapleader=" "

nnoremap \ :NERDTree<CR>

" Window / Split Management
noremap <C-L> <C-W><C-L>
noremap <C-H> <C-W><C-H>
noremap <C-K> <C-W><C-K>
noremap <C-J> <C-W><C-J>

" https://www.reddit.com/r/vim/wiki/vimrctips
" http://items.sjbach.com/319/configuring-vim-right
" http://nvie.com/posts/how-i-boosted-my-vim/
" http://net.tutsplus.com/articles/general/top-10-pitfalls-when-switching-to-vim/
" https://statico.github.io/vim3.html
" https://www.reddit.com/r/vim/comments/kbuv24/what_are_the_good_applications_of_automatic_marks/
" :h linewise :h linewise-register :h getreg :h getregtype :h setreg
" https://www.reddit.com/r/vim/comments/vvm61/why_does_vim_sometimes_pastes_multiple_lines/c5818m2/ linewise and characterwise

" https://github.com/romainl/idiomatic-vimrc/blob/master/idiomatic-vimrc.vim
" unlet! skip_defaults_vim
" source $VIMRUNTIME/defaults.vim

set nocompatible

"execute pathogen#infect()
set autoindent
" https://www.gilesorr.com/blog/vim-ftplugin.html
" http://vim.wikia.com/wiki/Keep_your_vimrc_file_clean
filetype plugin indent on
"set smartindent

" http://stackoverflow.com/questions/16631436/how-to-go-to-the-end-of-the-file-in-vim-while-preserving-the-current-column-unde
set nostartofline

set expandtab
set tabstop=4
set shiftwidth=4

set foldcolumn=1
set foldminlines=0
set foldopen-=search

set cursorline
" set cursorcolumn

" http://superuser.com/questions/271023/vim-can-i-disable-continuation-of-comments-to-the-next-line
set formatoptions-=cro

" shows status bar even with one window. 
" useful for the vim-airline plugin.
set laststatus=2 
                  
set relativenumber
set number
set showmatch
set hidden

" https://vimways.org/2018/the-power-of-diff/
set diffopt+=algorithm:patience

set backupdir=/tmp
set directory=/tmp

set vb t_vb=

" http://learnvimscriptthehardway.stevelosh.com/chapters/10.html
inoremap kj <Esc>
vnoremap kj <Esc>

syntax on
filetype on
filetype plugin on
filetype indent on

let g:haddock_browser = "/opt/firefox/firefox"

let g:python_host_prog="/usr/bin/python3"
" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
"let g:UltiSnipsExpandTrigger="<tab>"
let g:netrw_banner=0

set ruler
set showcmd
set hlsearch
set incsearch

set shortmess=atI

let mapleader = " "
" recover the normal behavior of , (for going back in character search for example) by double-tapping ,

" colorscheme zenburn
" colorscheme iceberg
colorscheme desert

" http://vim.wikia.com/wiki/Set_working_directory_to_the_current_file
" http://vim.wikia.com/wiki/Easy_edit_of_files_in_the_same_directory
" nnoremap <Leader>l :l %:p:h<CR>:pwd<CR>

noremap <script> <silent> <unique> <Leader>y "*y
noremap <script> <silent> <unique> <Leader>Y :%y*<CR>
noremap <script> <silent> <unique> <Leader>p "*p
noremap <script> <silent> <unique> <Leader>P "*P
noremap <script> <silent> <unique> <Leader>d "_d
noremap <script> <silent> <unique> <Leader>D :%d<CR>:w!<CR>
noremap <script> <silent> <unique> <Leader>e :Ex<CR>
noremap <script> <silent> <unique> <Leader>w :update!<CR>
noremap <script> <silent> <unique> <Leader>q :q!<CR>
"noremap <script> <silent> <unique> <Leader>x :x!<CR>
"noremap <unique> <Leader>x :ls<cr>:b<SPACE>
"noremap <unique> <Leader>f :FZF<cr>

" fzf
nnoremap <script> <silent> <unique> <Leader>f :Files<CR>
" nnoremap <script> <silent> <unique> <Leader>b :Buffers<CR>
" an experiment, b is akward to type!
nnoremap <script> <silent> <unique> <Leader>x :Buffers<CR>
nnoremap <script> <silent> <unique> <Leader>l :Lines<CR>
nnoremap <script> <silent> <unique> <Leader>c :Command<CR>
"
nnoremap <script> <silent> <unique> g<SPACE> :cnext<CR>
nnoremap <script> <silent> <unique> <SPACE> :lnext<CR>

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

" http://ellengummesson.com/blog/2015/08/01/dropping-ctrlp-and-other-vim-plugins/
nnoremap <script> <silent> <unique> <BS> <C-^>
" nnoremap <unique> <SPACE> :ls<cr>:b
" It is a bad idea to remap TAB, which is the same as ctrl-i.
" noremap <script> <silent> <unique> <TAB> gt

" other possible remaps: tab, space, backspace, return, 
"                        ctrl-m, ctrl-h, ctrl-j, ctrl-k, ctrl-n, ctrl-p, 
"                        perhaps s (when not taken by vim-sneak)
"                        much stuff starting with [, in particular [f and ]f which are deprecated.

" args `rg --files -g *.hs`
set wildignore+=.*
set wildignore+=dist
set wildignore+=dist/*
set wildignore+=target
set wildignore+=target/*
set wildignore+=.git
set wildignore+=.git/
set wildignore+=dist-newstyle
set wildignore+=dist-newstyle/*
set wildignore+=node_modules
set wildignore+=node_modules/*

" see also https://github.com/junegunn/fzf.vim for the Rg command
if executable('rg')
    set grepprg=rg\ --vimgrep\ --no-heading
endif

if has("multi_byte")
  if &termencoding == ""
    let &termencoding = &encoding
  endif
  set encoding=utf-8
  setglobal fileencoding=utf-8 nobomb
  set fileencodings=utf-8,latin1
endif

if has("win32") || has("win64")
   set directory=$TMP
end
