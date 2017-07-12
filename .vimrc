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

" Key remappings.
nnoremap <C-n> :bnext<CR>                                                         
nnoremap <C-p> :bprevious<CR>                                                     
nnoremap <C-b> :buffers<CR>                                                       
nnoremap <C-l> :vertical resize -5
nnoremap <C-h> :vertical resize +5
nnoremap <C-t> :resize +5
nnoremap <C-b> :resize -5

" Commit on every save if within a Git repository.
function! AutoGitCommit()
  call system('git rev-parse --git-dir > /dev/null 2>&1')
  if v:shell_error
    return
  endif
  let jira_issue = system('git branch | egrep "^\* feature/[A-Z_]{1,9}-[0-9]{1,}-.*" | cut -f2 -d "/" | cut -f1-2 -d "-"')
  if jira_issue == ""
    let jira_issue = ""
  endif
  let message = input('Enter a commit message for this change: ', '[' . expand('%') . '] ' . $USER . ' | ' . jira_issue . '| ')
  call system('git add ' . expand('%:p'))
  call system('git commit -m ' . shellescape(message, 1))
endfun
autocmd BufWritePost * call AutoGitCommit()

" Tim Popify my vim setup!
execute pathogen#infect()
