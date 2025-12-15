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
KRUN_HOME="${KRUN_HOME:-$HOME/.krun}"
KRUN_BIN_DIR="$KRUN_HOME/bin"
KRUN_URL="https://raw.githubusercontent.com/kevin197011/krun/refs/heads/main/bin/krun"

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
    krun::install::install_deps_centos
    krun::install::common
}

# debian code
krun::install::debian() {
    krun::install::install_deps_debian
    krun::install::common
}

# mac code
krun::install::mac() {
    krun::install::install_deps_mac
    krun::install::common
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

# common code
krun::install::common() {
    # Set download command
    local download_cmd
    if command -v curl >/dev/null 2>&1; then
        download_cmd="curl -fsSL"
    elif command -v wget >/dev/null 2>&1; then
        download_cmd="wget -qO-"
    else
        echo "Error: Failed to install curl or wget" >&2
        exit 1
    fi

    # Create directory and install
    mkdir -p "$KRUN_BIN_DIR"
    $download_cmd "$KRUN_URL" > "$KRUN_BIN_DIR/krun"
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
        echo "" >> "$shell_rc"
        echo "export PATH=\"\$PATH:$KRUN_BIN_DIR\"" >> "$shell_rc"
    fi

    export PATH="$PATH:$KRUN_BIN_DIR"

    echo "krun installed to $KRUN_BIN_DIR/krun"
    echo "Please run: source $shell_rc"
}

# run main
krun::install::run "$@"
