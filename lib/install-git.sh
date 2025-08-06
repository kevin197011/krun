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
user_name=${user_name:-kk}
user_email=${user_email:-kevin197011@outlook.com}

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
    yum install -y epel-release git curl wget || krun::install::git::binary_install
    krun::install::git::common
}

# debian code
krun::install::git::debian() {
    echo "Installing Git on Debian/Ubuntu..."
    apt-get update && apt-get install -y git curl wget || krun::install::git::binary_install
    krun::install::git::common
}

# mac code
krun::install::git::mac() {
    echo "Installing Git on macOS..."
    command -v git >/dev/null && echo "✓ Git already installed" && krun::install::git::common && return
    command -v brew >/dev/null && brew install git && echo "✓ Git installed via Homebrew" && krun::install::git::common && return
    krun::install::git::binary_install
}

# get latest version
krun::install::git::get_latest_version() {
    curl -fsSL https://api.github.com/repos/git/git/releases/latest 2>/dev/null | grep tag_name | head -n1 | cut -d '"' -f 4 || echo "v2.50.1"
}

# get system info
krun::install::git::get_system_info() {
    local arch=$(uname -m)
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')

    [[ "$arch" == "x86_64" ]] && arch="x86_64"
    [[ "$arch" == "aarch64" || "$arch" == "arm64" ]] && arch="arm64"
    [[ "$arch" != "x86_64" && "$arch" != "arm64" ]] && arch="x86_64"
    [[ "$os" != "darwin" ]] && os="linux"

    echo "$os $arch"
}

# common code
krun::install::git::common() {
    command -v git >/dev/null && krun::install::git::verify_installation && krun::install::git::configure_git && return
    krun::install::git::binary_install
}

# binary installation
krun::install::git::binary_install() {
    echo "Installing Git binary..."

    local system_info=$(krun::install::git::get_system_info)
    local os=$(echo "$system_info" | cut -d' ' -f1)
    local arch=$(echo "$system_info" | cut -d' ' -f2)
    local tag="$git_version"

    [[ "$git_version" == "latest" ]] && tag=$(krun::install::git::get_latest_version)
    [[ -z "$tag" ]] && tag="v2.50.1"
    tag=${tag#v}

    echo "Downloading Git ${tag} for ${os}/${arch}..."

    local temp_dir=$(mktemp -d)
    local download_url="https://github.com/git/git/releases/download/v${tag}/git-${tag}-${os}-${arch}.tar.gz"

    curl -fsSL "$download_url" -o "${temp_dir}/git.tar.gz" &&
        tar -xzf "${temp_dir}/git.tar.gz" -C "$temp_dir" &&
        mv "${temp_dir}/git-${tag}/bin/git" "/usr/local/bin/" &&
        chmod +x "/usr/local/bin/git" &&
        rm -rf "$temp_dir" &&
        echo "✓ Git installed successfully" &&
        krun::install::git::verify_installation &&
        krun::install::git::configure_git
}

# configure Git
krun::install::git::configure_git() {
    git config --global user.name "$user_name"
    git config --global user.email "$user_email"
    git config --global init.defaultBranch main 2>/dev/null || true
    git config --global pull.rebase false 2>/dev/null || true
    git config --global core.autocrlf input 2>/dev/null || true
    echo "✓ Git configured for $user_name <$user_email>"
}

# Verify Git installation
krun::install::git::verify_installation() {
    command -v git >/dev/null && echo "✓ Git installed: $(git --version)" || echo "✗ Git not found"
}

# run main
krun::install::git::run "$@"
