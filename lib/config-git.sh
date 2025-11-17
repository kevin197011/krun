#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-git.sh | bash

# vars
git_user_name=${git_user_name:-""}
git_user_email=${git_user_email:-""}

# run code
krun::config::git::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::git::centos() {
    echo "Configuring Git on CentOS/RHEL..."

    # Install git if not already installed
    if ! command -v git >/dev/null 2>&1; then
        yum install -y git
    fi

    krun::config::git::common
}

# debian code
krun::config::git::debian() {
    echo "Configuring Git on Debian/Ubuntu..."

    # Install git if not already installed
    if ! command -v git >/dev/null 2>&1; then
        apt-get update
        apt-get install -y git
    fi

    krun::config::git::common
}

# mac code
krun::config::git::mac() {
    echo "Configuring Git on macOS..."

    # Install git via Homebrew if not available
    if ! command -v git >/dev/null 2>&1; then
        if command -v brew >/dev/null 2>&1; then
            brew install git
        else
            echo "Git not found. Please install Xcode Command Line Tools or Homebrew."
            return 1
        fi
    fi

    krun::config::git::common
}

# common code
krun::config::git::common() {
    echo "Configuring Git settings..."

    # Verify git installation
    if ! command -v git >/dev/null 2>&1; then
        echo "✗ Git is not installed"
        return 1
    fi

    echo "✓ Git $(git --version)"

    # Configure user information
    krun::config::git::configure_user

    # Configure global settings
    krun::config::git::configure_global_settings

    # Configure SSH key
    krun::config::git::configure_ssh_key

    # Configure aliases
    krun::config::git::configure_aliases

    # Display configuration summary
    krun::config::git::display_summary
}

# Configure Git user information
krun::config::git::configure_user() {
    echo "Configuring Git user information..."

    # Get current user name and email
    local current_name=$(git config --global user.name 2>/dev/null || echo "")
    local current_email=$(git config --global user.email 2>/dev/null || echo "")

    # Set user name
    if [[ -n "$git_user_name" ]]; then
        git config --global user.name "$git_user_name"
        echo "✓ Set user name: $git_user_name"
    elif [[ -z "$current_name" ]]; then
        read -p "Enter your Git user name: " input_name
        if [[ -n "$input_name" ]]; then
            git config --global user.name "$input_name"
            echo "✓ Set user name: $input_name"
        fi
    else
        echo "✓ Current user name: $current_name"
    fi

    # Set user email
    if [[ -n "$git_user_email" ]]; then
        git config --global user.email "$git_user_email"
        echo "✓ Set user email: $git_user_email"
    elif [[ -z "$current_email" ]]; then
        read -p "Enter your Git user email: " input_email
        if [[ -n "$input_email" ]]; then
            git config --global user.email "$input_email"
            echo "✓ Set user email: $input_email"
        fi
    else
        echo "✓ Current user email: $current_email"
    fi
}

# Configure global Git settings
krun::config::git::configure_global_settings() {
    echo "Configuring global Git settings..."

    # Core settings
    git config --global core.editor "vim"
    git config --global core.autocrlf false
    git config --global core.safecrlf true
    git config --global core.filemode false

    # Push settings
    git config --global push.default simple
    git config --global push.followTags true

    # Pull settings
    git config --global pull.rebase false

    # Branch settings
    git config --global branch.autosetupmerge always
    git config --global branch.autosetuprebase always

    # Color settings
    git config --global color.ui auto
    git config --global color.branch auto
    git config --global color.diff auto
    git config --global color.status auto

    # Merge and diff tools
    git config --global merge.tool vimdiff
    git config --global diff.tool vimdiff

    # Credential helper
    if [[ "$(uname)" == "Darwin" ]]; then
        git config --global credential.helper osxkeychain
    elif [[ "$(uname)" == "Linux" ]]; then
        git config --global credential.helper store
    fi

    # Other useful settings
    git config --global init.defaultBranch main
    git config --global rerere.enabled true
    git config --global log.date iso

    echo "✓ Global Git settings configured"
}

# Configure SSH key for Git
krun::config::git::configure_ssh_key() {
    echo "Configuring SSH key for Git..."

    local ssh_dir="$HOME/.ssh"
    local ssh_key="$ssh_dir/id_rsa"
    local ssh_pub_key="$ssh_dir/id_rsa.pub"

    # Create .ssh directory if not exists
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    # Check if SSH key already exists
    if [[ -f "$ssh_key" ]] && [[ -f "$ssh_pub_key" ]]; then
        echo "✓ SSH key already exists"
        echo "Public key:"
        cat "$ssh_pub_key"
    else
        echo "Generating new SSH key..."
        local email=$(git config --global user.email 2>/dev/null || echo "user@example.com")

        # Generate SSH key
        ssh-keygen -t rsa -b 4096 -C "$email" -f "$ssh_key" -N ""

        # Set proper permissions
        chmod 600 "$ssh_key"
        chmod 644 "$ssh_pub_key"

        echo "✓ SSH key generated"
        echo "Public key:"
        cat "$ssh_pub_key"
    fi

    # Add SSH key to ssh-agent
    if command -v ssh-agent >/dev/null 2>&1; then
        eval "$(ssh-agent -s)" >/dev/null 2>&1
        ssh-add "$ssh_key" >/dev/null 2>&1
        echo "✓ SSH key added to ssh-agent"
    fi

    # Configure SSH for Git hosts
    local ssh_config="$ssh_dir/config"
    if [[ ! -f "$ssh_config" ]] || ! grep -q "github.com" "$ssh_config"; then
        cat >>"$ssh_config" <<EOF

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa

# GitLab
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_rsa

# Bitbucket
Host bitbucket.org
    HostName bitbucket.org
    User git
    IdentityFile ~/.ssh/id_rsa

EOF
        chmod 600 "$ssh_config"
        echo "✓ SSH config updated for Git hosts"
    fi

    echo ""
    echo "To add your SSH key to GitHub/GitLab/Bitbucket:"
    echo "1. Copy your public key:"
    echo "   cat ~/.ssh/id_rsa.pub"
    echo "2. Add it to your Git hosting service"
    echo "3. Test connection:"
    echo "   ssh -T git@github.com"
}

# Configure Git aliases
krun::config::git::configure_aliases() {
    echo "Configuring Git aliases..."

    # Status and log aliases
    git config --global alias.st status
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.df diff
    git config --global alias.lg "log --oneline --graph --decorate --all"
    git config --global alias.lgs "log --oneline --graph --decorate --stat"
    git config --global alias.last "log -1 HEAD"

    # Add and commit aliases
    git config --global alias.aa "add ."
    git config --global alias.cm "commit -m"
    git config --global alias.cam "commit -am"
    git config --global alias.amend "commit --amend"

    # Branch aliases
    git config --global alias.bd "branch -d"
    git config --global alias.bD "branch -D"
    git config --global alias.merged "branch --merged"
    git config --global alias.no-merged "branch --no-merged"

    # Remote aliases
    git config --global alias.ps push
    git config --global alias.pl pull
    git config --global alias.ft fetch
    git config --global alias.ru "remote update"

    # Stash aliases
    git config --global alias.sl "stash list"
    git config --global alias.sp "stash pop"
    git config --global alias.ss "stash save"

    # Reset aliases
    git config --global alias.unstage "reset HEAD"
    git config --global alias.undo "reset --soft HEAD~1"
    git config --global alias.hard-reset "reset --hard HEAD"

    echo "✓ Git aliases configured"
}

# Display configuration summary
krun::config::git::display_summary() {
    echo ""
    echo "=== Git Configuration Summary ==="
    echo "User name: $(git config --global user.name 2>/dev/null || echo 'Not set')"
    echo "User email: $(git config --global user.email 2>/dev/null || echo 'Not set')"
    echo "Default editor: $(git config --global core.editor 2>/dev/null || echo 'Not set')"
    echo "Default branch: $(git config --global init.defaultBranch 2>/dev/null || echo 'Not set')"
    echo ""
    echo "Useful Git aliases:"
    echo "  git st     - git status"
    echo "  git co     - git checkout"
    echo "  git br     - git branch"
    echo "  git ci     - git commit"
    echo "  git lg     - git log --oneline --graph --decorate --all"
    echo "  git aa     - git add ."
    echo "  git cm     - git commit -m"
    echo "  git ps     - git push"
    echo "  git pl     - git pull"
    echo ""
    echo "SSH key location: ~/.ssh/id_rsa.pub"
    echo ""
    echo "Git is configured and ready to use!"
}

# run main
krun::config::git::run "$@"
