colorscheme putty
hi Comment ctermfg=Blue
set hls
"set tw=79
"set formatoptions+=t
set colorcolumn=80
highlight ColorColumn ctermbg=236 guibg=#262626
set number
set relativenumber
highlight LineNr term=bold cterm=NONE ctermfg=Green ctermbg=NONE gui=NONE guifg=DarkGrey guibg=NONE
execute pathogen#infect()
set laststatus=2
"set statusline=%t\ %y\ format:\ %{&ff};\ [%c,%l]%{fugitive#statusline()}
set statusline=%t\ %y\ format:\ %{&ff};\ %{fugitive#statusline()};\ [%c,%l]
set statusline+=%=%p%%
highlight StatusLine term=None ctermfg=DarkGrey ctermbg=16
let g:netrw_liststyle=3
let g:jedi#popup_on_dot=0
let g:jedi#show_call_signatures=0

runtime plugin/dragvisuals.vim
vmap  <expr>  <LEFT>   DVB_Drag('left')
vmap  <expr>  <RIGHT>  DVB_Drag('right')
vmap  <expr>  <DOWN>   DVB_Drag('down')
vmap  <expr>  <UP>     DVB_Drag('up')
vmap  <expr>  D        DVB_Duplicate()
" Remove any introduced trailing whitespace after moving..
let g:DVB_TrimWS = 1

map <C-n> :NERDTreeToggle<CR>

set statusline+=%#warningmsg#                                               
set statusline+=%{SyntasticStatuslineFlag()}                                
set statusline+=%*                                                          
                                                                            
let g:syntastic_always_populate_loc_list = 1                                
let g:syntastic_auto_loc_list = 1                                           
let g:syntastic_check_on_open = 0                                          
let g:syntastic_check_on_wq = 0
let g:syntastic_python_checkers = ['pylint']

map <c-j> <c-w>j
map <c-k> <c-w>k
map <c-l> <c-w>l
map <c-h> <c-w>h

let mapleader = ","

nmap <leader>ln :set invnumber<CR>
nmap <leader>rn :set invrelativenumber<CR>
nmap <leader>sr :SyntasticReset<CR>
