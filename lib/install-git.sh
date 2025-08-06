#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-git.sh | bash

# vars
git_version=${git_version:-latest}

# run code
krun::install::git::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::git::centos() {
    echo "Installing Git on CentOS/RHEL..."

    # Install EPEL repository if not already installed
    yum install -y epel-release || true

    # Install Git and dependencies
    yum install -y git curl wget

    # Install additional Git tools
    yum install -y git-core git-daemon gitweb git-email || echo "⚠ Some Git tools installation failed"

    krun::install::git::common
}

# debian code
krun::install::git::debian() {
    echo "Installing Git on Debian/Ubuntu..."

    # Update package lists
    apt-get update

    # Install Git and dependencies
    apt-get install -y git curl wget

    # Install additional Git tools
    apt-get install -y git-core git-daemon gitweb git-email || echo "⚠ Some Git tools installation failed"

    krun::install::git::common
}

# mac code
krun::install::git::mac() {
    echo "Installing Git on macOS..."

    if command -v brew >/dev/null 2>&1; then
        brew install git
        echo "✓ Git installed via Homebrew"
        krun::install::git::verify_installation
        krun::install::git::configure_git
        return
    fi

    # Check if Git is already installed via Xcode Command Line Tools
    if command -v git >/dev/null 2>&1; then
        echo "✓ Git already installed (likely via Xcode Command Line Tools)"
        krun::install::git::verify_installation
        krun::install::git::configure_git
        return
    fi

    echo "Homebrew not found and Git not installed."
    echo "Please install Xcode Command Line Tools or Homebrew:"
    echo "  xcode-select --install"
    echo "  or"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    return 1
}

# get latest version
krun::install::git::get_latest_version() {
    curl -fsSL https://api.github.com/repos/git/git/releases/latest | grep tag_name | head -n1 | cut -d '"' -f 4
}

# get system info
krun::install::git::get_system_info() {
    local arch=$(uname -m)
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')

    # Map architecture
    [[ "$arch" == "x86_64" ]] && arch="x86_64"
    [[ "$arch" == "aarch64" || "$arch" == "arm64" ]] && arch="arm64"
    [[ "$arch" != "x86_64" && "$arch" != "arm64" ]] && arch="x86_64"

    # Map OS
    [[ "$os" != "darwin" ]] && os="linux"

    echo "$os $arch"
}

# common code
krun::install::git::common() {
    echo "Configuring Git..."

    # Check if Git is already installed
    if command -v git >/dev/null 2>&1; then
        echo "✓ Git already installed: $(git --version)"
        krun::install::git::verify_installation
        krun::install::git::configure_git
        return
    fi

    # If package manager installation failed, try manual installation
    echo "Package manager installation failed, trying manual installation..."
    krun::install::git::manual_install
}

# manual installation from source
krun::install::git::manual_install() {
    echo "Installing Git from source..."

    # Get system info and version
    local system_info=$(krun::install::git::get_system_info)
    local os=$(echo "$system_info" | cut -d' ' -f1)
    local arch=$(echo "$system_info" | cut -d' ' -f2)
    local tag="$git_version"

    [[ "$git_version" == "latest" ]] && tag=$(krun::install::git::get_latest_version)
    [[ -z "$tag" ]] && tag="v2.43.0"
    tag=${tag#v} # Remove 'v' prefix

    echo "Downloading Git ${tag} for ${os}/${arch}..."

    # Install dependencies for building from source
    if [[ "$os" == "linux" ]]; then
        if command -v yum >/dev/null 2>&1; then
            yum install -y gcc make curl-devel expat-devel gettext-devel openssl-devel zlib-devel perl-ExtUtils-MakeMaker
        elif command -v apt-get >/dev/null 2>&1; then
            apt-get install -y build-essential libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev
        fi
    fi

    # Download and build Git
    local temp_dir=$(mktemp -d)
    local download_url="https://github.com/git/git/archive/refs/tags/v${tag}.tar.gz"

    curl -fsSL "$download_url" -o "${temp_dir}/git.tar.gz" || {
        echo "✗ Failed to download Git"
        rm -rf "$temp_dir"
        return 1
    }

    tar -xzf "${temp_dir}/git.tar.gz" -C "$temp_dir" &&
        cd "${temp_dir}/git-${tag}" &&
        make prefix=/usr/local all &&
        make prefix=/usr/local install &&
        cd - &&
        rm -rf "$temp_dir" &&
        echo "✓ Git installed successfully from source"

    krun::install::git::verify_installation
    krun::install::git::configure_git
}

# configure Git
krun::install::git::configure_git() {
    echo "Configuring Git..."

    # Set default configuration if not already set
    if ! git config --global --get user.name >/dev/null 2>&1; then
        echo "Setting up Git configuration..."
        echo "Please configure your Git identity:"
        echo "  git config --global user.name \"Your Name\""
        echo "  git config --global user.email \"your.email@example.com\""
    fi

    # Set some useful defaults
    git config --global init.defaultBranch main 2>/dev/null || true
    git config --global pull.rebase false 2>/dev/null || true
    git config --global core.autocrlf input 2>/dev/null || true

    echo "✓ Git configuration completed"
}

# Verify Git installation
krun::install::git::verify_installation() {
    echo "Verifying Git installation..."

    if command -v git >/dev/null 2>&1; then
        echo "✓ Git command is available"
        git --version
        echo ""
        echo "=== Git Installation Summary ==="
        echo "Version: $(git --version 2>/dev/null || echo 'unknown')"
        echo "Installation path: $(which git)"
        echo ""
        echo "Common commands:"
        echo "  git init                        - Initialize repository"
        echo "  git clone <url>                - Clone repository"
        echo "  git add .                      - Stage changes"
        echo "  git commit -m \"message\"       - Commit changes"
        echo "  git push                       - Push to remote"
        echo "  git pull                       - Pull from remote"
        echo "  git status                     - Show status"
        echo "  git log                        - Show history"
        echo ""
        echo "Configuration:"
        echo "  git config --global user.name \"Your Name\""
        echo "  git config --global user.email \"your.email@example.com\""
        echo ""
        echo "Git is ready to use!"
    else
        echo "✗ Git command not found"
        return 1
    fi
}

# run main
krun::install::git::run "$@"
