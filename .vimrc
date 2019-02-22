" Tim Popify my vim setup!
execute pathogen#infect()

set encoding=utf8
let mapleader = ","
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

" Reload our .vimrc easily
nnoremap <leader>r :source $HOME/.vimrc<CR>

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
set textwidth=100

" Delek: pretty colorscheme.
colorscheme seti

" Enable the cursorline and cursorcolumn.
set cursorline
set cursorcolumn
au ColorScheme * hi CursorColumn ctermbg=233
au ColorScheme * hi CursorLine ctermbg=235
nnoremap <leader>l :set cursorline! cursorcolumn!<CR>

" Override highlight color
au ColorScheme * hi Visual ctermbg=blue

" Highlight search options
set hlsearch
au ColorScheme * hi Search ctermbg=167 ctermfg=235

" vim-cool shows the number of search results on the bottom.
let g:CoolTotalMatches = 1

" Set a bar at column 80 so that I can keep my code readable.
au ColorScheme * hi ColorColumn ctermbg=240
let &colorcolumn="80,".join(range(100,999),",")

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

" Key remappings.
nnoremap <C-n> :bnext<CR>
nnoremap <C-p> :bprevious<CR>
nnoremap <C-b> :buffers<CR>
nnoremap <C-l> :vertical resize -5
nnoremap <C-h> :vertical resize +5
nnoremap <C-t> :resize +5
nnoremap <C-b> :resize -5

" Markdown options
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_toc_autofit = 1
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_toml_frontmatter = 1
let g:vim_markdown_json_frontmatter = 1
let g:vim_markdown_strikethrough = 1
let g:vim_markdown_no_extensions_in_markdown = 1
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

" Syntastic Stuff; just the defaults
let g:syntastic_sh_checkers = ["shellcheck"]
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
nnoremap <leader>c :SyntasticReset<CR>

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
