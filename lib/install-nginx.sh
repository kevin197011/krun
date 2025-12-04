#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-nginx.sh | bash

# vars

# run code
krun::install::nginx::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::nginx::centos() {
    echo "Installing Nginx on RHEL/CentOS/Rocky/AlmaLinux/Fedora..."

    [[ "$OSTYPE" != "darwin"* ]] && [[ $EUID -ne 0 ]] && echo "✗ Please run as root" && return 1

    if command -v dnf >/dev/null 2>&1; then
        dnf install -y epel-release 2>/dev/null || true
        dnf install -y nginx
    else
        yum install -y epel-release 2>/dev/null || true
        yum install -y nginx
    fi

    krun::install::nginx::common
}

# debian code
krun::install::nginx::debian() {
    echo "Installing Nginx on Debian/Ubuntu..."

    [[ "$OSTYPE" != "darwin"* ]] && [[ $EUID -ne 0 ]] && echo "✗ Please run as root" && return 1

    apt-get update -qq
    apt-get install -y nginx

    krun::install::nginx::common
}

# mac code
krun::install::nginx::mac() {
    echo "Installing Nginx on macOS..."

    command -v brew >/dev/null || {
        echo "✗ Homebrew is required for macOS installation"
        return 1
    }

    brew install nginx

    krun::install::nginx::common
}

# common code
krun::install::nginx::common() {
    command -v nginx >/dev/null || {
        echo "✗ Nginx installation failed"
        return 1
    }

    echo "✓ Nginx installed: $(nginx -v 2>&1)"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "To start nginx on macOS:"
        echo "  sudo nginx"
        echo "  brew services start nginx"
    else
        systemctl enable nginx 2>/dev/null || true
        systemctl restart nginx 2>/dev/null || true

        if systemctl is-active --quiet nginx 2>/dev/null; then
            echo "✓ Nginx service started and enabled"
        else
            echo "⚠ Nginx service may not be running"
            echo "Check status: systemctl status nginx"
        fi
    fi

    echo ""
    echo "✓ Nginx installation completed"
}

# run main
krun::install::nginx::run "$@"
