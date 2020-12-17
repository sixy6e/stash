" code syntax highlighting
syntax enable

" colour schemes, and terminal colours. Depends on the type of terminal
" set background=dark
" let g:solarized_visibility = "high"
" let g:solarized_contrast = "high"
" let g:solarized_termcolors=256
" colorscheme solarized
"

" solarized was great, but zenburn is better
colorscheme zenburn

" let &t_Co=256

" hi Comment ctermfg=Blue " was good for a while, but was too dominant
set hls " highlight any search matches

" better to use when required within an edit session
"set paste

" line wrapping; good idea, but became annoying
"set tw=79
"set formatoptions+=t


" define and visualise an optimal column length
set colorcolumn=80,90
highlight ColorColumn ctermbg=240 guibg=#262626

" cursonline visualisation
set cursorline
highlight cursorline ctermbg=236

" line numbers
set number
set relativenumber " makes for very quick navigation using relative numbers

" line number, todo, and parenthesis highlighting
highlight LineNr ctermfg=Green
highlight Todo ctermfg=132
highlight MatchParen ctermfg=127

" Pathogen was good, vundle has more improvements
" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
Plugin 'tpope/vim-fugitive' " git integration
Plugin 'tpope/vim-unimpaired' " pairs mapping
Plugin 'scrooloose/nerdtree' " file/directory navigation and opening
Plugin 'scrooloose/syntastic' " code syntax checking
Plugin 'davidhalter/jedi-vim' " code goto's, help, prediction
Plugin 'altercation/vim-colors-solarized.git' " colourscheme
Plugin 'stormherz/tablify' " automatic table creation
Plugin 'gavinbeatty/dragvisuals.vim' " move blocks of text
Plugin 'vmchale/hlnext-fork' " search highlighting mods
Plugin 'jnurmine/zenburn' " colorscheme
Plugin 'dense-analysis/ale' " syntastic replacement
Plugin 'nixon/vim-vmath' " math on visual regions
Plugin 'lervag/vimtex' " latex documents
Plugin 'psf/black' " Python code formatter
Plugin 'Xuyuanp/nerdtree-git-plugin' " A plugin of NERDTree showing git status flags
Plugin 'bfrg/vim-jqplay' " A plugn that provides similar functionality as https://jqplay.org/
Plugin 'AndrewRadev/bufferize.vim' " Execute a :command and show the output in a temporary buffer
Plugin 'yegappan/taglist' " A plugin to efficiently browse through source code files (side window displays list of funcs, classes, global vars etc)

" All of your Plugins must be added before the following line
call vundle#end()            " required
" filetype plugin indent on    " required
filetype plugin on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on

" statusline config
set laststatus=2
"set statusline=%t\ %y\ format:\ %{&ff};\ [%c,%l]%{fugitive#statusline()}
set statusline=%t\ %y\ format:\ %{&ff};\ %{fugitive#statusline()};\ [%c,%l]
set statusline+=%=%p%%
highlight StatusLine term=None ctermfg=DarkGrey ctermbg=16

" jedi options
let g:netrw_liststyle=3
let g:jedi#popup_on_dot=0
let g:jedi#show_call_signatures=0

" drag visuals config
runtime plugin/dragvisuals.vim
vmap  <expr>  <LEFT>   DVB_Drag('left')
vmap  <expr>  <RIGHT>  DVB_Drag('right')
vmap  <expr>  <DOWN>   DVB_Drag('down')
vmap  <expr>  <UP>     DVB_Drag('up')
vmap  <expr>  D        DVB_Duplicate()

" Remove any introduced trailing whitespace after moving.. (for drag visuals)
let g:DVB_TrimWS = 1

" open/close NERDTree
map <C-n> :NERDTreeToggle<CR>

" Have replaced syntastic with ale
" statusline config
" set statusline+=%#warningmsg#                                               
" set statusline+=%{SyntasticStatuslineFlag()}                                
" set statusline+=%*                                                          
                                                                            
" syntastic config
" let g:syntastic_always_populate_loc_list = 1                                
" let g:syntastic_auto_loc_list = 1                                           
" let g:syntastic_check_on_open = 0                                          
" let g:syntastic_check_on_wq = 0
" let g:syntastic_python_checkers = ['pylint']

" ale config
let g:ale_completion_enabled = 1
let g:ale_echo_msg_format = '[%linter%] %code%: %s'

" split window navigation
map <c-j> <c-w>j
map <c-k> <c-w>k
map <c-l> <c-w>l
map <c-h> <c-w>h

" change the leader key
let mapleader = ","

let localleader = "\\"

" map some custom shortcuts
nmap <leader>n :set invnumber<CR>
nmap <leader>rn :set invrelativenumber<CR>
nmap <leader>nn :set invnumber<CR> <bar> :set invrelativenumber<CR>
nmap <leader>m :set mouse=a<CR>
nmap <leader>nm :set mouse=""<CR>
nmap <leader>sr :SyntasticReset<CR>
nmap <leader>sc :SyntasticCheck<CR>

" print full path filename
nmap <leader>fn :echo expand('%:p')<CR>

" taglist
nnoremap <silent> <F8> :TlistToggle<CR>
nnoremap <leader>tg :TlistToggle<CR>

let g:jedi#use_tabs_not_buffers = 1

" let b:tablify_horHeaderDelimiter = '='

vmap <expr>  ++  VMATH_YankAndAnalyse()
nmap         ++  vip++

" vimtex
let g:tex_flavor = 'latex'

" run Black on F9
nnoremap <F9> :Black<CR>

" add support for jsonlines
autocmd BufNewFile,BufRead *.jsonl set syntax=json

" splts and tabbed files
set splitbelow splitright

" simplify the adjustment of split resizing
noremap <silent> <C-Left> :vertical resize +1<CR>
noremap <silent> <C-Right> :vertical resize -1<CR>
noremap <silent> <C-Up> :resize +1<CR>
noremap <silent> <C-Down> :resize -1<CR>

" change between horizontal and vertical splits (to vertical, to horizontal)
map <leader>tv <C-w>t<C-w>H
map <leader>th <C-w>t<C-w>K

" Zstandard compression level for current buffer
" examples setting level 1 and level 19 compression
" :Zst -1
" :Zst -19
command -nargs=1 Zst execute 'let b:gzip_comp_arg=' . [<f-args>][0]

" black config
let g:black_linelength = 90
