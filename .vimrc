" Tim Popify my vim setup!
execute pathogen#infect()

" Globals
let g:TextWidthToggleOn = 1

" Buffer autocommands

" Set the default text width to 100
autocmd BufReadPre,FileReadPre * set formatoptions+=t
autocmd BufReadPre,FileReadPre * set textwidth=100
autocmd BufReadPre,FileReadPre * let &colorcolumn = (&l:textwidth - 20) . ",".join(range(&l:textwidth,999),",")
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()

" Close all quickfix and location windows
:nmap <leader>c :windo lcl\|ccl<CR>

au BufWrite * :Autoformat
augroup Markdown
  au FileType markdown vmap <leader><Bslash> :EasyAlign*<Bar><Enter>
  au FileType markdown setlocal textwidth=80
  au FileType markdown let &l:colorcolumn = (&l:textwidth - 20) . ",".join(range(&l:textwidth,999),",")
augroup end
augroup GitCommit
  au Filetype gitcommit setlocal textwidth=150
  au FileType gitcommit set nowrap
  au FileType python let &l:colorcolumn = (&l:textwidth - 20) . ",".join(range(&l:textwidth,999),",")
augroup end
augroup Python
  au FileType python let b:auto_save = 0
  au FileType python nmap <leader>d oimport pdb; pdb.set_trace() # vim breakpoint<Esc>
augroup end
augroup Text
  au FileType txt setlocal textwidth=0
  au FileType txt setlocal wrap
augroup end
augroup Ruby
  au FileType ruby let b:auto_save = 0
  au FileType ruby nmap <leader>d orequire 'pry'; binding.pry # vim breakpoint<Esc> 
augroup end
augroup Golang
  autocmd!
  let test#go#runner = 'ginkgo'
  autocmd FileType go nmap <leader><leader> :Ginkgo -strategy=vimux --randomize-suites --cover --label-filter='!e2e && !integration' test/...<CR>
  au FileType go setlocal textwidth=80
  autocmd BufWritePost *.go :TestFile -strategy=vimux --randomize-suites --cover --label-filter='!e2e && !integration'
  autocmd FileType go nmap <leader>x :GoInfo<CR>
augroup end


" Colorscheme autocommands
au ColorScheme * hi ColorColumn ctermbg=darkgray
au ColorScheme * hi CursorLine ctermbg=235
au ColorScheme * hi Visual ctermbg=blue
au ColorScheme * hi Search ctermbg=167 ctermfg=235

" Cursor Color options
set cursorline
set cursorcolumn

" Textwidth options
set formatoptions+=t " Wrap at textwidth

" Set modeline so that we can autoformat files based on top-file comments.
set modeline

set encoding=utf8
let mapleader = ","
let g:airline_powerline_fonts = 1
let g:airline_theme = 'atomic'
set t_Co=256

" vim-easy-align!
let g:table_mode_insert_column_after_map = 1
let g:table_mode_relign_map = 1

" Enable auto-save
set updatetime=2000 " Increase update time so that I can make quick edits.
let g:auto_save = 1
let g:auto_save_events = [ "CursorHold" ]

" Set Python path within Vim so that our linter works
let $PYTHONPATH = "."

" Helpful shell commands
nnoremap <leader>dc :!docker-compose up -d 
nnoremap <leader>dd :!docker-compose down<CR>
nnoremap <leader>dr :!docker-compose restart 
nnoremap <leader>y :!cat % \| pbcopy<CR>
nnoremap <leader>D :bufdo bd<CR>:NERDTreeToggle<CR>

" Set undo, backup and swap directories so that Vim doesn't leave
" all sorts of garbage within my working directory.
set undodir=~/.vim/undo//
set backupdir=~/.vim/backup//
set directory=~/.vim/swap//

" Highlight extra whitespace in Normal mode.
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/

" Reload our .vimrc easily
nnoremap <leader>r :source $HOME/.vimrc<CR>

" Easy save
nnoremap <leader>s :w<CR>

" Autoformatting options
let g:autoformat_autoindent = 0
let g:autoformat_retab = 0
let g:autoformat_remove_trailing_spaces = 0
nnoremap <leader><leader>f :Autoformat<CR>

" Language specific autoformatting options
let g:formatter_yapf_style = 'pep8' "Python

" Disable rbeautify formatter and modify to prevent a line of equals signs from appearing
let g:formatters_ruby = [ 'rubocop' ]
let g:formatdef_rubocop = "'rubocop --auto-correct -o /dev/null -s '.bufname('%').' \| sed -n 2,\\$p \| grep -Ev ^='"

" Reformat upon saving

" Spacing options.
" Tabstop: Number of spaces to add to tabs.
" Backspace: Number of characters to go back by within an indent.
" Shiftwidth: Number of spaces to add when indenting text in Normal mode.
set tabstop=2
set expandtab
set backspace=2
set shiftwidth=2


" Delek: pretty colorscheme.
colorscheme seti

" Override highlight color

" Highlight search options
set hlsearch

" vim-cool shows the number of search results on the bottom.
let g:CoolTotalMatches = 1

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
set incsearch
set ignorecase
set smartcase

" Enable line numbers.
set number
nnoremap <leader>n :set number!<cr>

" NERDtree things.
nmap <leader>t :NERDTreeToggle<cr>
nmap <leader>f :NERDTreeFind<cr>

" Key remappings.
nnoremap <C-n> :bnext<CR>
nnoremap <C-p> :bprevious<CR>
nnoremap <C-b> :buffers<CR>
nnoremap <C-h> :vertical resize -5<CR>
nnoremap <C-l> :vertical resize +5<CR>
nnoremap <leader>h :resize -5<CR>
nnoremap <leader>l :resize +5<CR>
nnoremap <CR> <C-w>w
nnoremap <leader>w :set wrap!<CR>

" Markdown options
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_toc_autofit = 1
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_toml_frontmatter = 1
let g:vim_markdown_json_frontmatter = 1
let g:vim_markdown_strikethrough = 1
let g:vim_markdown_no_extensions_in_markdown = 1
let g:vim_markdown_auto_insert_bullets = 0
let g:vim_markdown_new_list_item_indent = 0
let g:vim_markdown_fenced_languages = [
  \'csharp=cs',
  \'viml=vim',
  \'bash=sh',
  \'ini=dosini',
  \'go=golang',
  \'ruby=ruby',
  \'javascript=javascript',
  \'yaml=yaml',
  \'toml=toml',
  \'json=json'
\]

" JavaScript stuff
let g:javascript_plugin_jsdoc = 1
let g:javascript_plugin_ngdoc = 1
let g:used_javascript_libs = 'jquery,angularjs,angularui,react,jasmine,chai'

" Golang specific: Lint, test, and vet on save
let g:go_jump_to_error = 0
let g:go_metalinter_autosave = 1
let g:go_metalinter_autosave_enabled = ['deadcode', 'vet', 'golint', 'errcheck']
let g:go_fmt_fail_silently = 1

" Fugitive keybindings.

" Git status window.
nnoremap <C-g>s :Gstatus<CR>

" Interactive Git blame.
nnoremap <C-g>b :Gblame<CR>

" Push changes up.
nnoremap <C-g>p :Gpush<CR>

" Pull recent changes.
nnoremap <C-g>l :Gpull<CR>

" Do an interactive diff against the last staged bit of code.
nnoremap <C-g>d :Gdiff<CR>

nnoremap <leader>T :call TextWidthToggle()<CR>
nnoremap <leader>W :call WrapToggle()<CR>

function! WrapToggle()
  if stridx(&formatoptions, 't') > -1
    set formatoptions-=t
    hi ColorColumn ctermbg=22
    echom "wrapping disabled"
  else
    set formatoptions+=t
    hi ColorColumn ctermbg=240
    echom "wrapping enabled"
  endif
endfunction

function! TextWidthToggle()
  if g:TextWidthToggleOn
    let g:TextWidthToggleLastWidth = &textwidth
    let &textwidth = 0
    let &colorcolumn = 0
    let g:TextWidthToggleOn = 0
    echom "text width control disabled"
  else
    let &textwidth = g:TextWidthToggleLastWidth
    let &colorcolumn = (&textwidth - 20) . ",".join(range(&textwidth,999),",")
    let g:TextWidthToggleOn = 1
    echom "text width set to " . &textwidth . " characters"
  endif
endfunction

" Remove newlines from a visual region. Useful for tuir/rtv.
nnoremap <leader>N :'<,'>s/\n/ /g<CR>

" airline extensions
let g:airline#extensions#tabline#enabled = 1

" ALE configuration
let g:ale_sign_error = '❌'
let g:ale_sign_warning = '⚠️ '
hi SignColumn guibg=Red ctermbg=Red

:nmap ]a :ALENextWrap<CR>
:nmap [a :ALEPreviousWrap<CR>
:nmap ]A :ALELast
:nmap [A :ALEFirst

" ctrl-p configurations
let g:ctrlp_map = '<c-m>'
let g:ctrlp_cmd = 'CtrlP'

" vim-test configurations
let g:test#runner_commands = ['Ginkgo', 'RSpec', 'Nose']
:nmap ]t :TestFile -strategy=vimux<CR>

" optimized for using vim over ssh
:set ttyfast
:set lazyredraw
