#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-salt-master.sh | bash

# vars
BOOTSTRAP_URL="https://raw.githubusercontent.com/saltstack/salt-bootstrap/stable/bootstrap-salt.sh"

# run code
krun::install::salt_master::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::salt_master::centos() {
    [[ "$OSTYPE" != "darwin"* ]] && [[ $EUID -ne 0 ]] && echo "✗ Please run as root" && exit 1

    echo "Installing Salt Master on RHEL/CentOS/Rocky/AlmaLinux..."

    local bootstrap_file="/tmp/bootstrap-salt.sh"
    curl -fsSL "$BOOTSTRAP_URL" -o "$bootstrap_file"
    sh "$bootstrap_file" -M -x python3
    rm -f "$bootstrap_file"

    krun::install::salt_master::common
}

# debian code
krun::install::salt_master::debian() {
    [[ "$OSTYPE" != "darwin"* ]] && [[ $EUID -ne 0 ]] && echo "✗ Please run as root" && exit 1

    echo "Installing Salt Master on Debian/Ubuntu..."

    local bootstrap_file="/tmp/bootstrap-salt.sh"
    curl -fsSL "$BOOTSTRAP_URL" -o "$bootstrap_file"
    sh "$bootstrap_file" -M -x python3
    rm -f "$bootstrap_file"

    krun::install::salt_master::common
}

# mac code
krun::install::salt_master::mac() {
    echo "Installing Salt Master on macOS..."

    command -v brew >/dev/null || {
        echo "✗ Homebrew is required for macOS installation"
        exit 1
    }

    brew install saltstack

    krun::install::salt_master::common
}

# common code
krun::install::salt_master::common() {
    command -v salt-master >/dev/null || {
        echo "✗ Salt Master installation failed"
        exit 1
    }

    echo "✓ Salt Master installed: $(salt-master --version 2>&1 | head -1)"

    # Configure Salt Master
    local master_config="/etc/salt/master"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        master_config="/usr/local/etc/salt/master"
        [[ ! -f "$master_config" ]] && master_config="/opt/homebrew/etc/salt/master"
    fi

    if [[ -f "$master_config" ]]; then
        # Enable auto accept minion keys
        if ! grep -q "^auto_accept:" "$master_config"; then
            echo "" >> "$master_config"
            echo "# Auto accept minion keys" >> "$master_config"
            echo "auto_accept: True" >> "$master_config"
            echo "✓ Enabled auto accept minion keys"
        fi

        # Configure Salt API
        if ! grep -q "^rest_cherrypy:" "$master_config"; then
            echo "" >> "$master_config"
            echo "# Salt API configuration" >> "$master_config"
            echo "rest_cherrypy:" >> "$master_config"
            echo "  host: 0.0.0.0" >> "$master_config"
            echo "  port: 8000" >> "$master_config"
            echo "  disable_ssl: True" >> "$master_config"
            echo "✓ Configured Salt API on port 8000"
        fi

        # Configure external authentication (PAM)
        if ! grep -q "^external_auth:" "$master_config"; then
            echo "" >> "$master_config"
            echo "# External authentication for Salt API" >> "$master_config"
            echo "external_auth:" >> "$master_config"
            echo "  pam:" >> "$master_config"
            echo "    salt:" >> "$master_config"
            echo "      - .*" >> "$master_config"
            echo "      - '@runner'" >> "$master_config"
            echo "      - '@wheel'" >> "$master_config"
            echo "✓ Configured Salt API authentication (PAM)"
        fi
    fi

    # Install salt-api if not installed
    if [[ "$OSTYPE" != "darwin"* ]]; then
        if ! command -v salt-api >/dev/null 2>&1; then
            echo "Installing salt-api..."
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y salt-api 2>/dev/null || yum install -y salt-api 2>/dev/null || true
            elif command -v yum >/dev/null 2>&1; then
                yum install -y salt-api 2>/dev/null || true
            elif command -v apt-get >/dev/null 2>&1; then
                apt-get install -y salt-api 2>/dev/null || true
            fi
        fi
    fi

    if [[ "$OSTYPE" != "darwin"* ]]; then
        systemctl enable salt-master 2>/dev/null || true
        systemctl restart salt-master 2>/dev/null || true
        systemctl status salt-master --no-pager 2>/dev/null || true
        echo "✓ Salt Master service enabled and started"

        if command -v salt-api >/dev/null 2>&1; then
            systemctl enable salt-api 2>/dev/null || true
            systemctl start salt-api 2>/dev/null || true
            systemctl status salt-api --no-pager 2>/dev/null || true
            echo "✓ Salt API service enabled and started"
        fi
    else
        echo "To start Salt Master on macOS:"
        echo "  salt-master -d"
        echo "  brew services start saltstack"
    fi

    echo "✓ Salt Master installation completed"
    echo "  - Auto accept minion keys: enabled"
    echo "  - Salt API: http://0.0.0.0:8000 (authentication required)"
    echo "  - API Auth: PAM authentication enabled (user: salt)"
    echo "  - Note: Create 'salt' user or modify /etc/salt/master external_auth section"
}

# run main
krun::install::salt_master::run "$@"
