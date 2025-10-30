#!/usr/bin/env bash

# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-vim.sh | bash

# vars

# run code
krun::install::vim::run() {
    # default debian platform
    platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::vim::centos() {
    echo "Installing and configuring Vim on CentOS/RHEL..."

    # Install vim packages
    if command -v dnf >/dev/null 2>&1; then
        dnf install -y vim vim-enhanced vim-common
    else
        yum install -y vim vim-enhanced vim-common
    fi

    krun::install::vim::common
}

# debian code
krun::install::vim::debian() {
    echo "Installing and configuring Vim on Debian/Ubuntu..."

    # Update package list
    apt-get update

    # Install vim packages
    apt-get install -y vim vim-nox vim-common vim-runtime

    krun::install::vim::common
}

# mac code
krun::install::vim::mac() {
    echo "Installing and configuring Vim on macOS..."

    # Check if Homebrew is installed
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Please install Homebrew first:"
        echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        exit 1
    fi

    # Install vim via Homebrew
    brew install vim

    krun::install::vim::common
}

# common code
krun::install::vim::common() {
    echo "Configuring Vim with enhanced settings..."

    # Backup existing vimrc files
    if [[ -f /etc/vimrc ]]; then
        cp /etc/vimrc /etc/vimrc.bak.$(date +%Y%m%d) 2>/dev/null || true
    fi
    if [[ -f /etc/vim/vimrc ]]; then
        cp /etc/vim/vimrc /etc/vim/vimrc.bak.$(date +%Y%m%d) 2>/dev/null || true
    fi

    # Determine system vimrc location
    local system_vimrc=""
    if [[ -d /etc/vim ]]; then
        system_vimrc="/etc/vim/vimrc"
    elif [[ -f /etc/vimrc ]]; then
        system_vimrc="/etc/vimrc"
    else
        # Create directory if needed
        mkdir -p /etc/vim
        system_vimrc="/etc/vim/vimrc"
    fi

    # Create enhanced vimrc configuration
    tee "$system_vimrc" >/dev/null <<'EOF'
" Enhanced Vim Configuration for DevOps and Development
" Compatible with Vim 7.0+

" === Basic Settings ===
set nocompatible              " Use Vim defaults instead of Vi
set encoding=utf-8            " Set default encoding to UTF-8
set fileencoding=utf-8        " File encoding
set fileencodings=utf-8,gbk,gb2312,big5  " Auto detect file encoding

" === Display Settings ===
set number                    " Show line numbers
set relativenumber            " Show relative line numbers
set ruler                     " Show cursor position in status line
set showcmd                   " Show incomplete commands
set showmode                  " Show current mode
set laststatus=2              " Always show status line
set cmdheight=2               " Command line height
set scrolloff=8               " Keep 8 lines when scrolling
set sidescrolloff=15          " Keep 15 columns when side scrolling
set display=lastline          " Show as much as possible of the last line

" === Color and Syntax ===
syntax on                     " Enable syntax highlighting
set background=dark           " Dark background
if has('termguicolors')
    set termguicolors         " Enable true color support
endif
set cursorline                " Highlight current line
set showmatch                 " Show matching brackets
set matchtime=2               " Bracket matching time

" === Search Settings ===
set hlsearch                  " Highlight search results
set incsearch                 " Incremental search
set ignorecase                " Ignore case in search
set smartcase                 " Smart case sensitivity
set wrapscan                  " Wrap search around file

" === Indentation and Formatting ===
set autoindent                " Auto-indent new lines
set smartindent               " Smart auto-indenting
set cindent                   " C-style indenting
set expandtab                 " Use spaces instead of tabs
set tabstop=4                 " Tab width
set shiftwidth=4              " Indent width
set softtabstop=4             " Soft tab width
set shiftround                " Round indent to multiple of shiftwidth

" === Paste Mode Support ===
set paste                     " Enable paste mode by default
set pastetoggle=<F2>          " Toggle paste mode with F2
" Paste mode indicator in status line
set statusline=%<%f\ %h%m%r%{&paste?'[paste]':''}%=%-14.(%l,%c%V%)\ %P

" === File Handling ===
set autoread                  " Auto-reload changed files
set autowrite                 " Auto-save before commands like :next
set hidden                    " Allow hidden buffers
set backup                    " Keep backup files
set writebackup               " Make backup before overwriting
set backupdir=~/.vim/backup   " Backup directory
set directory=~/.vim/swap     " Swap file directory
if has('persistent_undo')
    set undofile              " Persistent undo
    set undodir=~/.vim/undo   " Undo directory
endif

" === Completion and Wildmenu ===
set wildmenu                  " Enhanced command completion
set wildmode=longest:full,full " Tab completion behavior
set wildignore=*.o,*.obj,*.bak,*.exe,*.pyc,*.DS_Store,*.db
set completeopt=menu,longest  " Completion options

" === Performance ===
set lazyredraw                " Don't redraw during macros
set ttyfast                   " Fast terminal connection
set timeout                   " Enable timeout for key codes
set timeoutlen=1000           " Timeout length
set ttimeoutlen=50            " Key code timeout

" === Mouse Support ===
if has('mouse')
    set mouse=a               " Enable mouse in all modes
endif

" === Key Mappings ===
" Leader key
let mapleader = ","

" Window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Clear search highlighting
nnoremap <silent> <Esc><Esc> :nohlsearch<CR>

" Quick save and quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>

" Buffer navigation
nnoremap <leader>n :bnext<CR>
nnoremap <leader>p :bprev<CR>
nnoremap <leader>d :bdelete<CR>

" Toggle line numbers
nnoremap <leader>l :set number!<CR>

" Toggle paste mode
nnoremap <leader>pp :set paste!<CR>

" Ruby specific mappings
autocmd FileType ruby nnoremap <leader>r :!ruby %<CR>
autocmd FileType ruby nnoremap <leader>i :!irb<CR>

" === File Type Specific Settings ===
augroup FileTypeSettings
    autocmd!
    " Python
    autocmd FileType python setlocal tabstop=4 shiftwidth=4 expandtab
    autocmd FileType python setlocal textwidth=79
    
    " JavaScript/TypeScript
    autocmd FileType javascript,typescript setlocal tabstop=2 shiftwidth=2 expandtab
    
    " HTML/CSS
    autocmd FileType html,css,scss setlocal tabstop=2 shiftwidth=2 expandtab
    
    " YAML
    autocmd FileType yaml setlocal tabstop=2 shiftwidth=2 expandtab
    
    " JSON
    autocmd FileType json setlocal tabstop=2 shiftwidth=2 expandtab
    
    " Shell scripts
    autocmd FileType sh,bash setlocal tabstop=4 shiftwidth=4 expandtab
    
    " Makefile (must use tabs)
    autocmd FileType make setlocal noexpandtab
    
    " Go
    autocmd FileType go setlocal tabstop=4 shiftwidth=4 noexpandtab
    
    " Ruby
    autocmd FileType ruby setlocal tabstop=2 shiftwidth=2 expandtab
    autocmd FileType ruby setlocal textwidth=80
    autocmd FileType ruby setlocal commentstring=#\ %s
    
    " Markdown
    autocmd FileType markdown setlocal wrap linebreak textwidth=80
augroup END

" === Auto Commands ===
augroup AutoCommands
    autocmd!
    " Remove trailing whitespace on save
    autocmd BufWritePre * :%s/\s\+$//e
    
    " Return to last edit position when opening files
    autocmd BufReadPost *
        \ if line("'\"") > 0 && line("'\"") <= line("$") |
        \   exe "normal! g`\"" |
        \ endif
    
    " Auto-create directories for backup, swap, and undo
    autocmd VimEnter *
        \ if !isdirectory($HOME."/.vim/backup") |
        \   call mkdir($HOME."/.vim/backup", "p") |
        \ endif |
        \ if !isdirectory($HOME."/.vim/swap") |
        \   call mkdir($HOME."/.vim/swap", "p") |
        \ endif |
        \ if !isdirectory($HOME."/.vim/undo") |
        \   call mkdir($HOME."/.vim/undo", "p") |
        \ endif
augroup END

" === Status Line ===
set statusline=%<%f                    " Filename
set statusline+=\ %h%m%r               " Help, modified, readonly flags
set statusline+=%{&paste?'[PASTE]':''} " Paste mode indicator
set statusline+=%=                     " Right align
set statusline+=%-14.(%l,%c%V%)        " Line, column, virtual column
set statusline+=\ %P                   " Percentage through file

" === Security ===
set modelines=0                        " Disable modelines for security
set nomodeline                         " Disable modeline processing

" === Clipboard ===
if has('clipboard')
    set clipboard=unnamed              " Use system clipboard
    if has('unnamedplus')
        set clipboard=unnamed,unnamedplus
    endif
endif

" === Terminal Settings ===
if &term =~ '256color'
    set t_Co=256                       " Enable 256 colors
endif

" === Local Customizations ===
" Source local vimrc if it exists
if filereadable(expand("~/.vimrc.local"))
    source ~/.vimrc.local
endif
EOF

    # Create user vimrc template
    local user_home="${HOME:-/root}"
    if [[ ! -f "$user_home/.vimrc" ]]; then
        tee "$user_home/.vimrc" >/dev/null <<'EOF'
" Personal Vim Configuration
" This file sources the system vimrc and adds personal customizations

" Source system vimrc
if filereadable("/etc/vimrc")
    source /etc/vimrc
elseif filereadable("/etc/vim/vimrc")
    source /etc/vim/vimrc
endif

" === Personal Customizations ===
" Add your custom settings here

" Example: Different color scheme
" colorscheme desert

" Example: Custom key mappings
" nnoremap <leader>t :tabnew<CR>

" Example: Custom settings
" set relativenumber!
EOF
        echo "✓ Created user vimrc template: $user_home/.vimrc"
    fi

    # Create vim directories for all users
    for user_dir in /root /home/*; do
        if [[ -d "$user_dir" ]]; then
            mkdir -p "$user_dir/.vim/backup" "$user_dir/.vim/swap" "$user_dir/.vim/undo"
            # Set proper ownership if not root
            if [[ "$user_dir" != "/root" ]]; then
                local username=$(basename "$user_dir")
                chown -R "$username:$username" "$user_dir/.vim" 2>/dev/null || true
            fi
        fi
    done

    # Test vim configuration
    if vim --version >/dev/null 2>&1; then
        echo "✓ Vim installation verified"
        vim --version | head -2
    else
        echo "✗ Vim installation failed"
        exit 1
    fi

    # Create vim usage guide
    tee /usr/local/share/vim-usage-guide.txt >/dev/null <<'EOF'
=== Vim Enhanced Configuration Usage Guide ===

Paste Mode:
  F2                    - Toggle paste mode on/off
  :set paste            - Enable paste mode
  :set nopaste          - Disable paste mode
  [PASTE] indicator     - Shows in status line when paste mode is active

Key Mappings:
  Leader key: ,         - Custom command prefix
  
  Window Navigation:
  Ctrl+h/j/k/l         - Move between windows
  
  File Operations:
  ,w                   - Save file
  ,q                   - Quit
  ,x                   - Save and quit
  
  Buffer Navigation:
  ,n                   - Next buffer
  ,p                   - Previous buffer
  ,d                   - Delete buffer
  
  Utility:
  ,l                   - Toggle line numbers
  ,pp                  - Toggle paste mode
  Esc Esc              - Clear search highlighting
  
  Ruby Specific (in .rb files):
  ,r                   - Run current Ruby file
  ,i                   - Open IRB (Interactive Ruby)

File Type Support:
  - Python: 4 spaces, 79 char width
  - JavaScript/TypeScript: 2 spaces
  - HTML/CSS: 2 spaces
  - YAML/JSON: 2 spaces
  - Shell scripts: 4 spaces
  - Ruby: 2 spaces, 80 char width
  - Go: tabs (no expansion)
  - Markdown: word wrap, 80 char width

Features:
  - Syntax highlighting
  - Auto-indentation
  - Line numbers (absolute and relative)
  - Search highlighting
  - Persistent undo
  - Auto-backup
  - Trailing whitespace removal
  - Return to last edit position
  - System clipboard integration
  - Mouse support

Configuration Files:
  System: /etc/vim/vimrc or /etc/vimrc
  User: ~/.vimrc
  Local: ~/.vimrc.local (for additional customizations)
  
Directories:
  ~/.vim/backup        - Backup files
  ~/.vim/swap          - Swap files  
  ~/.vim/undo          - Undo files
EOF

    echo ""
    echo "=== Vim Installation and Configuration Complete ==="
    echo "✓ Vim packages installed"
    echo "✓ Enhanced configuration applied"
    echo "✓ Paste mode support enabled (F2 to toggle)"
    echo "✓ User directories created"
    echo "✓ Usage guide: /usr/local/share/vim-usage-guide.txt"
    echo ""
    echo "Key Features:"
    echo "  - Paste mode: F2 key or :set paste"
    echo "  - Leader key: , (comma)"
    echo "  - Window navigation: Ctrl+hjkl"
    echo "  - Auto-backup and persistent undo"
    echo "  - File type specific settings (Python, JS, Ruby, Go, etc.)"
    echo "  - Ruby development support (,r to run, ,i for IRB)"
    echo "  - System clipboard integration"
    echo ""
    echo "To customize further, edit ~/.vimrc or ~/.vimrc.local"
}

# run main
krun::install::vim::run "$@"
