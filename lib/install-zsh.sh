#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-zsh.sh | bash

# vars

# run code
krun::install::zsh::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::zsh::centos() {
    echo "Installing Zsh on CentOS/RHEL..."

    # Install EPEL repository if not already installed
    yum install -y epel-release || true

    # Install zsh
    yum install -y zsh

    krun::install::zsh::common
}

# debian code
krun::install::zsh::debian() {
    echo "Installing Zsh on Debian/Ubuntu..."

    # Update package lists
    apt-get update

    # Install zsh
    apt-get install -y zsh

    krun::install::zsh::common
}

# mac code
krun::install::zsh::mac() {
    echo "Installing Zsh on macOS..."

    # macOS comes with zsh by default in recent versions
    if command -v zsh >/dev/null 2>&1; then
        echo "✓ Zsh is already available on macOS"
    else
        # Install via Homebrew if available and needed
        if command -v brew >/dev/null 2>&1; then
            brew install zsh
        else
            echo "⚠ Zsh not found and Homebrew not available"
            return 1
        fi
    fi

    krun::install::zsh::common
}

# common code
krun::install::zsh::common() {
    echo "Configuring Zsh..."

    # Verify zsh installation
    if ! command -v zsh >/dev/null 2>&1; then
        echo "✗ Zsh installation failed"
        return 1
    fi

    echo "✓ Zsh installed successfully"
    zsh --version

    # Check if zsh is in /etc/shells
    if ! grep -q "$(which zsh)" /etc/shells 2>/dev/null; then
        echo "Adding zsh to /etc/shells..."
        which zsh | sudo tee -a /etc/shells
    fi

    # Get current user (handle sudo case)
    local current_user="${SUDO_USER:-${USER}}"

    # Prompt to change default shell
    echo ""
    echo "Zsh installation completed!"
    echo "Current shell: $SHELL"
    echo "Zsh location: $(which zsh)"
    echo ""

    if [[ "$SHELL" != "$(which zsh)" ]]; then
        echo "To change your default shell to zsh, run:"
        echo "  chsh -s $(which zsh) ${current_user}"
        echo ""
        echo "Or run this command now:"
        read -p "Change default shell to zsh now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if chsh -s "$(which zsh)" "${current_user}"; then
                echo "✓ Default shell changed to zsh"
                echo "Please log out and back in for the change to take effect"
            else
                echo "✗ Failed to change default shell"
                echo "You can manually change it later with: chsh -s $(which zsh)"
            fi
        fi
    else
        echo "✓ Zsh is already your default shell"
    fi

    # Create basic zsh configuration if not exists
    local zshrc_file="$HOME/.zshrc"
    if [[ ! -f "$zshrc_file" ]]; then
        echo "Creating basic .zshrc configuration..."
        cat >"$zshrc_file" <<'EOF'
# Basic Zsh configuration
# Enable colors and change prompt
autoload -U colors && colors
PS1="%{$fg[green]%}%n@%m:%{$fg[blue]%}%~%{$reset_color%}$ "

# History configuration
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE

# Enable completion
autoload -U compinit
compinit

# Enable auto-correction
setopt CORRECT

# Enable glob patterns
setopt EXTENDED_GLOB

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Key bindings
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# Set title
case $TERM in
    xterm*|rxvt*)
        precmd() { print -Pn "\e]0;%n@%m: %~\a" }
        ;;
esac

EOF
        echo "✓ Created basic .zshrc configuration"
    else
        echo "✓ .zshrc already exists"
    fi

    echo ""
    echo "=== Zsh Installation Summary ==="
    echo "Version: $(zsh --version)"
    echo "Location: $(which zsh)"
    echo "Config file: $zshrc_file"
    echo ""
    echo "Next steps:"
    echo "1. Log out and back in (if you changed the default shell)"
    echo "2. Consider installing Oh My Zsh for enhanced features:"
    echo "   curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-oh_my_zsh.sh | bash"
    echo ""
    echo "Zsh is ready to use!"
}

# run main
krun::install::zsh::run "$@"
