#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/install.sh | bash

# vars
KRUN_VERSION="${KRUN_VERSION:-2.0.0}"
KRUN_REPO="https://github.com/kevin197011/krun"
KRUN_RELEASES_URL="${KRUN_REPO}/releases/download/v${KRUN_VERSION}"

# run code
krun::install::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::centos() {
    [[ "$OSTYPE" != "darwin"* ]] && [[ $EUID -ne 0 ]] && echo "✗ Please run as root" && exit 1

    krun::install::install_deps_centos

    # Try to install from RPM package
    if krun::install::install_from_package "rpm"; then
        return 0
    fi

    # Fallback to direct binary installation
    krun::install::install_binary
}

# debian code
krun::install::debian() {
    [[ "$OSTYPE" != "darwin"* ]] && [[ $EUID -ne 0 ]] && echo "✗ Please run as root" && exit 1

    krun::install::install_deps_debian

    # Try to install from DEB package
    if krun::install::install_from_package "deb"; then
        return 0
    fi

    # Fallback to direct binary installation
    krun::install::install_binary
}

# mac code
krun::install::mac() {
    krun::install::install_deps_mac
    krun::install::install_binary
}

# install deps for centos
krun::install::install_deps_centos() {
    if command -v python3 >/dev/null 2>&1 && (command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1); then
        return 0
    fi
    echo "Installing dependencies..."
    if command -v dnf >/dev/null 2>&1; then
        ! command -v python3 >/dev/null 2>&1 && sudo dnf install -y python3
        ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1 && sudo dnf install -y curl
    else
        ! command -v python3 >/dev/null 2>&1 && sudo yum install -y python3
        ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1 && sudo yum install -y curl
    fi
}

# install deps for debian
krun::install::install_deps_debian() {
    if command -v python3 >/dev/null 2>&1 && (command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1); then
        return 0
    fi
    echo "Installing dependencies..."
    sudo apt-get update -qq
    ! command -v python3 >/dev/null 2>&1 && sudo apt-get install -y python3
    ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1 && sudo apt-get install -y curl
}

# install deps for mac
krun::install::install_deps_mac() {
    if command -v python3 >/dev/null 2>&1 && (command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1); then
        return 0
    fi
    echo "Installing dependencies..."
    if ! command -v brew >/dev/null 2>&1; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    ! command -v python3 >/dev/null 2>&1 && brew install python3
    ! command -v curl >/dev/null 2>&1 && brew install curl
}

# install from package (deb/rpm)
krun::install::install_from_package() {
    local pkg_type="$1"
    local download_cmd
    local pkg_file
    local arch

    # Detect architecture
    arch=$(uname -m)
    [[ "$arch" == "x86_64" ]] && arch="amd64"
    [[ "$arch" == "aarch64" ]] && arch="arm64"

    # Set download command
    if command -v curl >/dev/null 2>&1; then
        download_cmd="curl -fsSL -o"
    elif command -v wget >/dev/null 2>&1; then
        download_cmd="wget -qO"
    else
        return 1
    fi

    # Construct package filename
    if [[ "$pkg_type" == "deb" ]]; then
        pkg_file="krun_${KRUN_VERSION}_${arch}.deb"
    else
        pkg_file="krun_${KRUN_VERSION}_${arch}.rpm"
    fi

    local pkg_url="${KRUN_RELEASES_URL}/${pkg_file}"
    local temp_pkg="/tmp/${pkg_file}"

    echo "Downloading ${pkg_file}..."
    if $download_cmd "$temp_pkg" "$pkg_url" 2>/dev/null; then
        echo "Installing package..."
        if [[ "$pkg_type" == "deb" ]]; then
            if dpkg -i "$temp_pkg" 2>/dev/null || apt-get install -y "$temp_pkg" 2>/dev/null; then
                rm -f "$temp_pkg"
                echo "krun installed successfully from package"
                return 0
            fi
        else
            if rpm -i "$temp_pkg" 2>/dev/null || yum install -y "$temp_pkg" 2>/dev/null || dnf install -y "$temp_pkg" 2>/dev/null; then
                rm -f "$temp_pkg"
                echo "krun installed successfully from package"
                return 0
            fi
        fi
        rm -f "$temp_pkg"
    fi

    return 1
}

# install binary directly (fallback)
krun::install::install_binary() {
    local download_cmd
    local KRUN_HOME="${KRUN_HOME:-$HOME/.krun}"
    local KRUN_BIN_DIR="$KRUN_HOME/bin"
    local KRUN_URL="https://raw.githubusercontent.com/kevin197011/krun/refs/heads/main/bin/krun"

    # Set download command
    if command -v curl >/dev/null 2>&1; then
        download_cmd="curl -fsSL"
    elif command -v wget >/dev/null 2>&1; then
        download_cmd="wget -qO-"
    else
        echo "Error: curl or wget is required" >&2
        exit 1
    fi

    # Create directory and install
    mkdir -p "$KRUN_BIN_DIR"
    $download_cmd "$KRUN_URL" >"$KRUN_BIN_DIR/krun"
    chmod +x "$KRUN_BIN_DIR/krun"

    # Add to PATH
    local shell_rc
    if [ -f "$HOME/.zshrc" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        shell_rc="$HOME/.bashrc"
    else
        shell_rc="$HOME/.bashrc"
    fi

    if ! grep -q "$KRUN_BIN_DIR" "$shell_rc" 2>/dev/null; then
        echo "" >>"$shell_rc"
        echo "export PATH=\"\$PATH:$KRUN_BIN_DIR\"" >>"$shell_rc"
    fi

    export PATH="$PATH:$KRUN_BIN_DIR"

    echo "krun installed to $KRUN_BIN_DIR/krun"
    echo "Please run: source $shell_rc"
}

# run main
krun::install::run "$@"
