set undodir=~/.vim/undo//
set backupdir=~/.vim/backup//
set directory=~/.vim/swap//

set ts=2 sw=2                                                                     
set bs=2                                                                          
set nowrap                                                                        
colorscheme delek                                                                 
hi ColorColumn ctermbg=darkred                                                    
hi CursorLine cterm=NONE ctermbg=magenta                                          
set colorcolumn=100                                                                
set expandtab                                                                     
set visualbell t_vb=                                                              
set wildmode=longest,list,full                                                    
set wildmenu                                                                      
set ruler                                                                         
syntax on                                                                         
set tw=0                                                                         
set formatoptions+=t                                                              
filetype indent plugin on                                                         
nnoremap <C-n> :bnext<CR>                                                         
nnoremap <C-p> :bprevious<CR>                                                     
nnoremap <C-b> :buffers<CR>                                                       
execute pathogen#infect()
