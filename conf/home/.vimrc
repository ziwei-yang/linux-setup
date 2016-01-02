" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

if has("vms")
	set nobackup		" do not keep a backup file, use versions instead
else
	set backup		" keep a backup file
endif

set history=50		" keep 50 lines of command line history
set ruler		" show the cursor position all the time
set showcmd		" display incomplete commands
set incsearch		" do incremental searching
set nu			"show line number

" Don't use Ex mode, use Q for formatting
map Q gq

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-U> <C-G>u<C-U>

" In many terminal emulators the mouse works just fine, thus enable it.
if has('mouse')
	set mouse=a
endif

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
	syntax on
	set hlsearch
endif

" Only do this part when compiled with support for autocommands.
if has("autocmd")

	" Enable file type detection.
	" Use the default filetype settings, so that mail gets 'tw' set to 72,
	" 'cindent' is on in C files, etc.
	" Also load indent files, to automatically do language-dependent indenting.
	filetype plugin indent on

	" Put these in an autocmd group, so that we can delete them easily.
	augroup vimrcEx
		au!

		" For all text files set 'textwidth' to 78 characters.
		autocmd FileType text setlocal textwidth=78

		" When editing a file, always jump to the last known cursor position.
		" Don't do it when the position is invalid or when inside an event handler
		" (happens when dropping a file on gvim).
		" Also don't do it when the mark is in the first line, that is the default
		" position when opening a file.
		autocmd BufReadPost *
					\ if line("'\"") > 1 && line("'\"") <= line("$") |
					\   exe "normal! g`\"" |
					\ endif
	augroup END
else
	set autoindent		" always set autoindenting on
endif " has("autocmd")

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
	command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
				\ | wincmd p | diffthis
endif

" show the file being editing
set statusline+=%f

" always show tab bar
set showtabline=2

let g:rubycomplete_buffer_loading = 1
let g:rubycomplete_classes_in_global = 1
let g:rubycomplete_rails = 1

" tricks in BDB tutorial
map! ^F sed -e "s/* //" \| fmt \| sed -e "s/^[  ]*/&* /"
map! ^L sed -e "s/ *\\\\ *$//" \| fmt \| sed -e "s/$/ \\\\/"

" To insert space characters whenever the tab key is pressed
" set expandtab
" To control the number of space characters that will be inserted when the tab
" key is pressed
set tabstop=8
" To change the number of space characters inserted for indentation
set shiftwidth=8

" auto replace tab to 8 spaces
" au BufWritePost *.* silent! %s/\t/        /g
" auto generate ctags when saving c/cpp files
" au BufWritePost *.c,*.cpp,*.h silent! !ctags -R --languages=C,C++ &
" auto generate ctags when saving tcl files
" au BufWritePost *.tcl silent! !ctags -R --languages=TCL &
" auto generate HTML previews when saving markdown files
" au BufWritePost *.md !cat /home/zwyang/Dropbox/Documents/BDB/coverage_report/style.css > /tmp/md_preview_cache.html && cat %:p | Markdown.pl --html4tags >> /tmp/md_preview_cache.html && w3m /tmp/md_preview_cache.html

" search tags file towards root
set tags=./tags;/

" I preferred do not put backup files in the same folder 
set backupdir=~/.vim/backupfiles,~/tmp,.
" The same to swap file directory
set directory=~/.vim/swapfiles,~/tmp,.

" map <F12> to save
nmap <F12> :w<CR>
inoremap <F12> <Esc>:w<CR>

" map F3/F4 to switch windows 
" nmap <F3> :wincmd h<CR>
" nmap <F4> :wincmd l<CR>

" map F2 to open file in Gnome
" nmap <F2> :!gnome-open %:p<CR>

" map <F5> to previous tab, <F6> to next tab
nmap <F5> gT
inoremap <F5> <Esc>gT
nmap <F6> gt
inoremap <F6> <Esc>gt
nmap <C-k> :tabprevious<CR>
inoremap <C-k> <Esc>:tabprevious<CR>
nmap <C-j> :tabnext<CR>
inoremap <C-j> <Esc>:tabnext<CR>

" Display extra whitespace and tab
" set list listchars=tab:»·,trail:·
set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<

" highlight 80 width char
highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%81v.\+/
" test this is a very very very very very very  very very  very  very  very  very  very  long sentence
" au BufWritePost *.c,*.cpp,*.h,*.tcl highlight OverLength ctermbg=red ctermfg=white guibg=#592929

" set default color scheme
" colorscheme elflord
colorscheme default

" set term=linux

" encoding
set encoding=utf-8
set fileencodings=utf-8,gb2312,big5,latin1
set termencoding=utf-8
set ffs=unix,dos,mac
set formatoptions+=m
set formatoptions+=B

" set mark column color
hi! link SignColumn   LineNr
hi! link ShowMarksHLl DiffAdd
hi! link ShowMarksHLu DiffChange

" status line
hi StatusLine ctermbg=darkgrey ctermfg=grey

set statusline=%<%F\%h%m%r%k\ Encoding:[%{(&fenc==\"\")?&enc:&fenc}%{(&bomb?\",BOM\":\"\")}]%=\%-14.(%l/%L,%c%V%)\ %P
set laststatus=2   " Always show the status line - use 2 lines for the status bar


let @b = '0i# j'
let @c = '0i//j'
let @x = '0xxj'
let @d = '0xj'

" Automatic indentation for different languange.
autocmd FileType html setlocal shiftwidth=2 tabstop=2
autocmd FileType ruby setlocal shiftwidth=2 tabstop=2
autocmd Filetype javascript setlocal ts=4 sw=4 sts=0 expandtab
autocmd Filetype coffeescript setlocal ts=4 sw=4 sts=0 expandtab
autocmd Filetype jade setlocal ts=4 sw=4 sts=0 expandtab
