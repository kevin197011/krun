#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-mc.sh | bash

# vars

# run code
krun::install::mc::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::mc::centos() {
    echo "Installing Midnight Commander on CentOS/RHEL..."

    # Install EPEL repository if needed
    yum install -y epel-release || true

    # Install mc
    yum install -y mc

    krun::install::mc::common
}

# debian code
krun::install::mc::debian() {
    echo "Installing Midnight Commander on Debian/Ubuntu..."

    # Update package lists
    apt-get update

    # Install mc
    apt-get install -y mc

    krun::install::mc::common
}

# mac code
krun::install::mc::mac() {
    echo "Installing Midnight Commander on macOS..."

    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew is required for mc installation on macOS"
        return 1
    fi

    # Install mc via Homebrew
    brew install mc

    krun::install::mc::common
}

# common code
krun::install::mc::common() {
    echo "Configuring Midnight Commander..."

    # Verify installation
    if ! command -v mc >/dev/null 2>&1; then
        echo "✗ Midnight Commander installation failed"
        return 1
    fi

    echo "✓ Midnight Commander installed successfully"
    mc --version

    # Create basic configuration directory
    mkdir -p "$HOME/.config/mc"

    echo ""
    echo "=== Midnight Commander Installation Summary ==="
    echo "Version: $(mc --version | head -1)"
    echo "Executable: $(which mc)"
    echo "Config directory: $HOME/.config/mc"
    echo ""
    echo "Basic usage:"
    echo "  mc                    - Start Midnight Commander"
    echo "  F1                    - Help"
    echo "  F3                    - View file"
    echo "  F4                    - Edit file"
    echo "  F5                    - Copy files"
    echo "  F6                    - Move files"
    echo "  F8                    - Delete files"
    echo "  F10                   - Quit"
    echo "  Tab                   - Switch between panels"
    echo ""
    echo "Midnight Commander is ready to use!"
}

# run main
krun::install::mc::run "$@"
