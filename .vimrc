set encoding=utf8
let g:airline_powerline_fonts = 1
let g:airline_theme = 'atomic'
set t_Co=256

" Set undo, backup and swap directories so that Vim doesn't leave
" all sorts of garbage within my working directory.
set undodir=~/.vim/undo//
set backupdir=~/.vim/backup//
set directory=~/.vim/swap//

" Highlight extra whitespace in Normal mode.
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()

" Spacing options.
" Tabstop: Number of spaces to add to tabs.
" Backspace: Number of characters to go back by within an indent.
" Shiftwidth: Number of spaces to add when indenting text in Normal mode.
set tabstop=2
set expandtab
set backspace=2
set shiftwidth=2 

" Nowrap: Don't wrap text unless I say so explicitly.
" Textwidth: Autowrap at column n (where n is right of the equals sign)
set formatoptions+=t                                                              
set nowrap                                                                        

" Delek: pretty colorscheme.
colorscheme delek          

" Set a bar at column 80 so that I can keep my code readable.                                                       
hi ColorColumn ctermbg=darkred                                                    
hi CursorLine cterm=NONE ctermbg=magenta                                          
set colorcolumn=80                                                               

" Expandtab: Use spaces instead of hard tabs. 
set expandtab                                                                     

" Disable the annoying flashing bell.
set visualbell t_vb=                                                              

" Enable autocompletion within the wildmenu.
" See also: https://stackoverflow.com/questions/9511253/how-to-effectively-use-vim-wildmenu
set wildmode=longest:list,full                                                    
set wildmenu                                                                      

" Enable the column and row ruler at the bottom of the screen.
set ruler                                                     

" Enable syntax highlighting and filetype-based indenting.                    
set autoindent
syntax on                                                                         
filetype indent plugin on                                                         

" incsearch: Enable incremental searching
" ignorecase: Case-insensitive searching
" smartcase: ...unless there is a capital letter
" nohlsearch: Don't highlight the search result.
set incsearch
set ignorecase
set smartcase
set nohlsearch

" Enable line numbers.
set number

" NERDtree things.
let mapleader = ","
nmap <leader>t :NERDTreeToggle<cr>

" Key remappings.
nnoremap <C-n> :bnext<CR>                                                         
nnoremap <C-p> :bprevious<CR>                                                     
nnoremap <C-b> :buffers<CR>                                                       
nnoremap <C-l> :vertical resize -5
nnoremap <C-h> :vertical resize +5
nnoremap <C-t> :resize +5
nnoremap <C-b> :resize -5

" JavaScript stuff
let g:javascript_plugin_jsdoc = 1
let g:javascript_plugin_ngdoc = 1
let g:used_javascript_libs = 'jquery,angularjs,angularui,react,jasmine,chai'

" Syntastic Stuff; just the defaults
let g:syntastic_sh_checkers = ["shellcheck"]
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" Tim Popify my vim setup!
execute pathogen#infect()
