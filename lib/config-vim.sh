#!/usr/bin/env bash

# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-vim.sh | bash

# vars

# run code
krun::config::vim::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::vim::centos() {
    echo "Configuring Vim on CentOS/RHEL..."

    # Install vim if not already installed
    yum install -y vim vim-enhanced

    krun::config::vim::common
}

# debian code
krun::config::vim::debian() {
    echo "Configuring Vim on Debian/Ubuntu..."

    # Install vim if not already installed
    apt-get update
    apt-get install -y vim

    krun::config::vim::common
}

# mac code
krun::config::vim::mac() {
    echo "Configuring Vim on macOS..."

    # Install/upgrade vim via Homebrew if available
    if command -v brew >/dev/null 2>&1; then
        brew install vim || brew upgrade vim || true
    fi

    krun::config::vim::common
}

# common code
krun::config::vim::common() {
    echo "Configuring Vim settings..."

    # Find the correct vimrc location
    local vimrc_file=""
    local vimrc_locations=(
        "/etc/vim/vimrc"
        "/etc/vimrc"
        "/usr/share/vim/vimrc"
    )

    for location in "${vimrc_locations[@]}"; do
        if [[ -f "$location" ]]; then
            vimrc_file="$location"
            break
        fi
    done

    # If no system vimrc found, create one
    if [[ -z "$vimrc_file" ]]; then
        if [[ -d "/etc/vim" ]]; then
            vimrc_file="/etc/vim/vimrc"
        else
            vimrc_file="/etc/vimrc"
        fi
        touch "$vimrc_file"
    fi

    echo "Using vimrc file: $vimrc_file"

    # Backup original vimrc
    if [[ -f "$vimrc_file" ]] && [[ ! -f "${vimrc_file}.bak" ]]; then
        cp "$vimrc_file" "${vimrc_file}.bak"
        echo "✓ Backed up original vimrc"
    fi

    # Configure basic vim settings
    cat >>"$vimrc_file" <<'EOF'

" === KRUN VIM CONFIGURATION ===
" Basic settings
set nocompatible              " Use vim defaults
set encoding=utf-8            " Set default encoding
set number                    " Show line numbers
set relativenumber            " Show relative line numbers
set ruler                     " Show cursor position
set showcmd                   " Show incomplete commands
set showmode                  " Show current mode
set wildmenu                  " Enhanced command completion
set wildmode=list:longest     " Tab completion behavior

" Search settings
set hlsearch                  " Highlight search results
set incsearch                 " Incremental search
set ignorecase                " Ignore case in search
set smartcase                 " Smart case sensitivity

" Indentation and formatting
set autoindent                " Auto-indent new lines
set smartindent               " Smart auto-indenting
set expandtab                 " Use spaces instead of tabs
set tabstop=4                 " Tab width
set shiftwidth=4              " Indent width
set softtabstop=4             " Soft tab width
set paste                     " Paste mode (prevents auto-indenting)

" Visual settings
set background=dark           " Dark background
syntax on                     " Enable syntax highlighting
set cursorline                " Highlight current line
set showmatch                 " Show matching brackets
set laststatus=2              " Always show status line

" File handling
set autoread                  " Auto-reload changed files
set backup                    " Keep backup files
set backupdir=~/.vim/backup   " Backup directory
set directory=~/.vim/swap     " Swap file directory
set undofile                  " Persistent undo
set undodir=~/.vim/undo       " Undo directory

" Performance
set lazyredraw                " Don't redraw during macros
set ttyfast                   " Fast terminal connection

" Key mappings
nnoremap <C-h> <C-w>h         " Navigate windows with Ctrl+hjkl
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Clear search highlighting with Esc
nnoremap <Esc> :noh<CR><Esc>

" File type specific settings
autocmd FileType python setlocal tabstop=4 shiftwidth=4 expandtab
autocmd FileType javascript setlocal tabstop=2 shiftwidth=2 expandtab
autocmd FileType html setlocal tabstop=2 shiftwidth=2 expandtab
autocmd FileType css setlocal tabstop=2 shiftwidth=2 expandtab
autocmd FileType yaml setlocal tabstop=2 shiftwidth=2 expandtab
autocmd FileType json setlocal tabstop=2 shiftwidth=2 expandtab

" Create necessary directories
if !isdirectory($HOME."/.vim/backup")
    call mkdir($HOME."/.vim/backup", "p")
endif
if !isdirectory($HOME."/.vim/swap")
    call mkdir($HOME."/.vim/swap", "p")
endif
if !isdirectory($HOME."/.vim/undo")
    call mkdir($HOME."/.vim/undo", "p")
endif

" === END KRUN VIM CONFIGURATION ===
EOF

    echo "✓ Vim configuration applied"

    # Create user vimrc template
    local user_vimrc="$HOME/.vimrc"
    if [[ ! -f "$user_vimrc" ]]; then
        cat >"$user_vimrc" <<'EOF'
" Personal vim configuration
" Add your custom settings here

" Source system vimrc
if filereadable("/etc/vimrc")
    source /etc/vimrc
elseif filereadable("/etc/vim/vimrc")
    source /etc/vim/vimrc
endif

" Personal customizations
" colorscheme desert
" set background=light

EOF
        echo "✓ Created user vimrc template: $user_vimrc"
    fi

    # Test vim configuration
    echo "Testing vim configuration..."
    if vim --version >/dev/null 2>&1; then
        echo "✓ Vim is working"
    else
        echo "✗ Vim test failed"
    fi

    echo ""
    echo "=== Vim Configuration Summary ==="
    echo "System vimrc: $vimrc_file"
    echo "User vimrc: $user_vimrc"
    echo ""
    echo "Features enabled:"
    echo "  - Line numbers and relative numbers"
    echo "  - Syntax highlighting"
    echo "  - Smart indentation (4 spaces)"
    echo "  - Search highlighting"
    echo "  - Persistent undo"
    echo "  - Auto backup"
    echo "  - Window navigation with Ctrl+hjkl"
    echo ""
    echo "Vim is ready to use!"
}

# run main
krun::config::vim::run "$@"
