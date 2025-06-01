#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-oh_my_zsh.sh | bash

# vars

# run code
krun::install::oh_my_zsh::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::oh_my_zsh::centos() {
    echo "Installing Oh My Zsh on CentOS/RHEL..."

    # Install prerequisites
    yum install -y git curl zsh

    krun::install::oh_my_zsh::common
}

# debian code
krun::install::oh_my_zsh::debian() {
    echo "Installing Oh My Zsh on Debian/Ubuntu..."

    # Install prerequisites
    apt-get update
    apt-get install -y git curl zsh

    krun::install::oh_my_zsh::common
}

# mac code
krun::install::oh_my_zsh::mac() {
    echo "Installing Oh My Zsh on macOS..."

    # Check prerequisites
    if ! command -v git >/dev/null 2>&1; then
        if command -v brew >/dev/null 2>&1; then
            brew install git
        else
            echo "Git is required. Please install Xcode Command Line Tools or Homebrew first."
            return 1
        fi
    fi

    krun::install::oh_my_zsh::common
}

# common code
krun::install::oh_my_zsh::common() {
    echo "Installing Oh My Zsh..."

    # Check if zsh is installed
    if ! command -v zsh >/dev/null 2>&1; then
        echo "✗ Zsh is not installed. Please install zsh first:"
        echo "  curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-zsh.sh | bash"
        return 1
    fi

    # Check if git is installed
    if ! command -v git >/dev/null 2>&1; then
        echo "✗ Git is required but not installed"
        return 1
    fi

    # Check if curl is installed
    if ! command -v curl >/dev/null 2>&1; then
        echo "✗ Curl is required but not installed"
        return 1
    fi

    local oh_my_zsh_dir="$HOME/.oh-my-zsh"

    # Remove existing installation if exists
    if [[ -d "$oh_my_zsh_dir" ]]; then
        echo "Existing Oh My Zsh installation found. Backing up..."
        mv "$oh_my_zsh_dir" "${oh_my_zsh_dir}.backup.$(date +%Y%m%d-%H%M%S)"
    fi

    # Download and install Oh My Zsh
    echo "Downloading Oh My Zsh..."
    export RUNZSH=no # Don't run zsh after installation
    export CHSH=no   # Don't change shell automatically

    curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash

    # Verify installation
    if [[ ! -d "$oh_my_zsh_dir" ]]; then
        echo "✗ Oh My Zsh installation failed"
        return 1
    fi

    echo "✓ Oh My Zsh installed successfully"

    # Configure .zshrc
    krun::install::oh_my_zsh::configure_zshrc

    # Install useful plugins
    krun::install::oh_my_zsh::install_plugins

    echo ""
    echo "=== Oh My Zsh Installation Summary ==="
    echo "Installation directory: $oh_my_zsh_dir"
    echo "Configuration file: $HOME/.zshrc"
    echo ""
    echo "Installed plugins:"
    echo "  - zsh-syntax-highlighting"
    echo "  - zsh-autosuggestions"
    echo "  - zsh-completions"
    echo ""
    echo "Default theme: robbyrussell"
    echo ""
    echo "To start using Oh My Zsh:"
    echo "1. Make sure zsh is your default shell: chsh -s \$(which zsh)"
    echo "2. Open a new terminal or run: zsh"
    echo ""
    echo "Useful commands:"
    echo "  omz update    - Update Oh My Zsh"
    echo "  omz plugin    - Manage plugins"
    echo "  omz theme     - Manage themes"
}

# Configure .zshrc with Oh My Zsh
krun::install::oh_my_zsh::configure_zshrc() {
    local zshrc_file="$HOME/.zshrc"

    # Backup existing .zshrc if it exists and is not from Oh My Zsh
    if [[ -f "$zshrc_file" ]] && ! grep -q "oh-my-zsh" "$zshrc_file"; then
        cp "$zshrc_file" "${zshrc_file}.backup.$(date +%Y%m%d-%H%M%S)"
        echo "✓ Backed up existing .zshrc"
    fi

    # Create enhanced .zshrc configuration
    cat >"$zshrc_file" <<'EOF'
# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="robbyrussell"

# Enable command auto-correction
ENABLE_CORRECTION="true"

# Display red dots whilst waiting for completion
COMPLETION_WAITING_DOTS="true"

# Disable marking untracked files under VCS as dirty
DISABLE_UNTRACKED_FILES_DIRTY="true"

# History timestamp format
HIST_STAMPS="yyyy-mm-dd"

# Plugins to load
plugins=(
    git
    docker
    docker-compose
    kubectl
    helm
    terraform
    aws
    gcloud
    node
    npm
    yarn
    ruby
    python
    golang
    rust
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-completions
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# User configuration
export LANG=en_US.UTF-8
export EDITOR='vim'

# Compilation flags
export ARCHFLAGS="-arch x86_64"

# Custom aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dimg='docker images'
alias dexec='docker exec -it'

# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'

# Custom functions
function mkcd() {
    mkdir -p "$1" && cd "$1"
}

function extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

EOF

    echo "✓ Enhanced .zshrc configuration created"
}

# Install useful Oh My Zsh plugins
krun::install::oh_my_zsh::install_plugins() {
    local custom_plugins_dir="$HOME/.oh-my-zsh/custom/plugins"

    echo "Installing additional plugins..."

    # Install zsh-syntax-highlighting
    if [[ ! -d "$custom_plugins_dir/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom_plugins_dir/zsh-syntax-highlighting"
        echo "✓ Installed zsh-syntax-highlighting"
    else
        echo "✓ zsh-syntax-highlighting already installed"
    fi

    # Install zsh-autosuggestions
    if [[ ! -d "$custom_plugins_dir/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_plugins_dir/zsh-autosuggestions"
        echo "✓ Installed zsh-autosuggestions"
    else
        echo "✓ zsh-autosuggestions already installed"
    fi

    # Install zsh-completions
    if [[ ! -d "$custom_plugins_dir/zsh-completions" ]]; then
        git clone https://github.com/zsh-users/zsh-completions "$custom_plugins_dir/zsh-completions"
        echo "✓ Installed zsh-completions"
    else
        echo "✓ zsh-completions already installed"
    fi
}

# run main
krun::install::oh_my_zsh::run "$@"
