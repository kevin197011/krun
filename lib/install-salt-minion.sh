#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-salt-minion.sh | bash

# vars
SALT_MASTER_HOST="${SALT_MASTER_HOST:-}"
BOOTSTRAP_URL="https://raw.githubusercontent.com/saltstack/salt-bootstrap/stable/bootstrap-salt.sh"

# run code
krun::install::salt_minion::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::salt_minion::centos() {
    [[ "$OSTYPE" != "darwin"* ]] && [[ $EUID -ne 0 ]] && echo "✗ Please run as root" && exit 1

    echo "Installing Salt Minion on RHEL/CentOS/Rocky/AlmaLinux..."

    local bootstrap_file="/tmp/bootstrap-salt.sh"
    curl -fsSL "$BOOTSTRAP_URL" -o "$bootstrap_file"
    sh "$bootstrap_file" -x python3
    rm -f "$bootstrap_file"

    krun::install::salt_minion::common
}

# debian code
krun::install::salt_minion::debian() {
    [[ "$OSTYPE" != "darwin"* ]] && [[ $EUID -ne 0 ]] && echo "✗ Please run as root" && exit 1

    echo "Installing Salt Minion on Debian/Ubuntu..."

    local bootstrap_file="/tmp/bootstrap-salt.sh"
    curl -fsSL "$BOOTSTRAP_URL" -o "$bootstrap_file"
    sh "$bootstrap_file" -x python3
    rm -f "$bootstrap_file"

    krun::install::salt_minion::common
}

# mac code
krun::install::salt_minion::mac() {
    echo "Installing Salt Minion on macOS..."

    command -v brew >/dev/null || {
        echo "✗ Homebrew is required for macOS installation"
        exit 1
    }

    brew install saltstack

    krun::install::salt_minion::common
}

# common code
krun::install::salt_minion::common() {
    command -v salt-minion >/dev/null || {
        echo "✗ Salt Minion installation failed"
        exit 1
    }

    echo "✓ Salt Minion installed: $(salt-minion --version 2>&1 | head -1)"

    # Configure salt minion
    if [[ -n "$SALT_MASTER_HOST" ]]; then
        local minion_config="/etc/salt/minion"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            minion_config="/usr/local/etc/salt/minion"
            [[ ! -f "$minion_config" ]] && minion_config="/opt/homebrew/etc/salt/minion"
        fi

        if [[ -f "$minion_config" ]]; then
            if [[ "$OSTYPE" != "darwin"* ]]; then
                sed -i "s/#master: salt/master: ${SALT_MASTER_HOST}/" "$minion_config"
            else
                sed -i '' "s/#master: salt/master: ${SALT_MASTER_HOST}/" "$minion_config"
            fi
            echo "✓ Salt Minion configured to connect to master: ${SALT_MASTER_HOST}"
        fi
    fi

    if [[ "$OSTYPE" != "darwin"* ]]; then
        systemctl enable salt-minion 2>/dev/null || true
        systemctl start salt-minion 2>/dev/null || true
        systemctl status salt-minion --no-pager 2>/dev/null || true
        echo "✓ Salt Minion service enabled and started"
    else
        echo "To start Salt Minion on macOS:"
        echo "  salt-minion -d"
        echo "  brew services start saltstack"
    fi

    echo "✓ Salt Minion installation completed"
}

# run main
krun::install::salt_minion::run "$@"
