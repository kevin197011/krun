#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-golang.sh | bash

# vars
golang_version=${golang_version:-latest}

# run code
krun::install::golang::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::golang::centos() {
    echo "Installing Go on CentOS/RHEL..."

    # Install via package manager as fallback
    yum install -y golang || {
        echo "Package manager installation failed, using asdf..."
    }

    krun::install::golang::common
}

# debian code
krun::install::golang::debian() {
    echo "Installing Go on Debian/Ubuntu..."

    # Update package lists
    apt-get update

    # Install via package manager
    apt-get install -y golang-go || {
        echo "Package manager installation failed, using asdf..."
    }

    # Install build tools that might be needed
    apt-get install -y build-essential git curl

    krun::install::golang::common
}

# mac code
krun::install::golang::mac() {
    echo "Installing Go on macOS..."

    # Install via Homebrew if available
    if command -v brew >/dev/null 2>&1; then
        brew install go || {
            echo "Homebrew installation failed, using asdf..."
        }
    else
        echo "Homebrew not found, using asdf..."
    fi

    krun::install::golang::common
}

# common code
krun::install::golang::common() {
    echo "Installing Go ${golang_version} via asdf..."

    # Check if asdf is available
    if ! command -v asdf >/dev/null 2>&1; then
        echo "asdf not found. Installing Go manually..."
        krun::install::golang::manual_install
        return
    fi

    # Install Go plugin for asdf
    asdf plugin-add golang https://github.com/kennyp/asdf-golang.git || echo "Go plugin already installed"

    # Update plugin
    asdf plugin-update golang || true

    # Install specific Go version
    echo "Installing Go ${golang_version}..."
    asdf install golang ${golang_version} || {
        echo "Failed to install Go ${golang_version}, trying latest stable..."
        latest_version=$(asdf latest golang 2>/dev/null || echo "1.21.0")
        asdf install golang ${latest_version}
        asdf global golang ${latest_version}
    }

    # Set global version
    asdf global golang ${golang_version} || asdf global golang $(asdf latest golang 2>/dev/null || echo "1.21.0")

    # Refresh shell
    asdf reshim golang || true

    krun::install::golang::verify_installation
}

# Manual Go installation
krun::install::golang::manual_install() {
    echo "Installing Go manually..."

    local go_version="1.21.0"
    local arch
    arch=$(uname -m)
    case $arch in
    x86_64) arch="amd64" ;;
    arm64 | aarch64) arch="arm64" ;;
    *)
        echo "Unsupported architecture: $arch"
        return 1
        ;;
    esac

    local os
    os=$(uname -s | tr '[:upper:]' '[:lower:]')

    local download_url="https://golang.org/dl/go${go_version}.${os}-${arch}.tar.gz"
    local install_dir="/usr/local"

    echo "Downloading Go ${go_version} for ${os}-${arch}..."

    # Remove existing Go installation
    rm -rf ${install_dir}/go

    # Download and extract
    cd /tmp
    curl -L -o go.tar.gz "${download_url}"
    tar -C ${install_dir} -xzf go.tar.gz
    rm go.tar.gz

    # Set up environment
    cat >>/etc/profile.d/golang.sh <<EOF
export PATH=\$PATH:/usr/local/go/bin
export GOPATH=\$HOME/go
export PATH=\$PATH:\$GOPATH/bin
EOF

    # Set for current session
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin

    echo "✓ Go installed manually to ${install_dir}/go"
    krun::install::golang::verify_installation
}

# Verify Go installation
krun::install::golang::verify_installation() {
    echo "Verifying Go installation..."

    # Check go command
    if command -v go >/dev/null 2>&1; then
        echo "✓ go command is available"
        go version
    else
        echo "✗ go command not found"
        echo "You may need to restart your shell or source your profile"
        return 1
    fi

    # Check GOPATH
    if [[ -n "${GOPATH:-}" ]]; then
        echo "✓ GOPATH is set to: $GOPATH"
    else
        echo "⚠ GOPATH not set, using default"
    fi

    # Test Go functionality
    echo "Testing Go functionality..."
    go env GOVERSION 2>/dev/null && echo "✓ Go environment is working"

    # Create a simple test program
    local test_dir="/tmp/go-test-$$"
    mkdir -p "$test_dir"
    cd "$test_dir"

    cat >main.go <<EOF
package main

import "fmt"

func main() {
    fmt.Println("Hello, Go!")
}
EOF

    if go run main.go 2>/dev/null | grep -q "Hello, Go!"; then
        echo "✓ Go can compile and run programs"
    else
        echo "✗ Go test program failed"
    fi

    # Clean up
    cd /
    rm -rf "$test_dir"

    echo "Go installation verification completed."
    echo ""
    echo "Go is ready to use!"
    echo "Try: go version"
    echo "Create your first project: mkdir hello && cd hello && go mod init hello"
}

# run main
krun::install::golang::run "$@"
