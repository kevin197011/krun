#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-tinyproxy.sh | bash

# vars

# run code
krun::install::tinyproxy::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::tinyproxy::centos() {
    echo "Installing Tinyproxy on CentOS/RHEL..."

    # Install EPEL repository
    yum install -y epel-release

    # Install Tinyproxy
    yum install -y tinyproxy

    krun::install::tinyproxy::common
}

# debian code
krun::install::tinyproxy::debian() {
    echo "Installing Tinyproxy on Debian/Ubuntu..."

    # Update package lists
    apt-get update

    # Install Tinyproxy
    apt-get install -y tinyproxy

    krun::install::tinyproxy::common
}

# mac code
krun::install::tinyproxy::mac() {
    echo "Installing Tinyproxy on macOS..."

    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew is required for Tinyproxy installation on macOS"
        return 1
    fi

    # Install Tinyproxy via Homebrew
    brew install tinyproxy

    krun::install::tinyproxy::common
}

# common code
krun::install::tinyproxy::common() {
    echo "Configuring Tinyproxy..."

    # Verify installation
    if ! command -v tinyproxy >/dev/null 2>&1; then
        echo "✗ Tinyproxy installation failed"
        return 1
    fi

    echo "✓ Tinyproxy installed successfully"

    # Find config file location
    local config_file=""
    local possible_configs=(
        "/etc/tinyproxy/tinyproxy.conf"
        "/etc/tinyproxy.conf"
        "/usr/local/etc/tinyproxy.conf"
    )

    for config in "${possible_configs[@]}"; do
        if [[ -f "$config" ]]; then
            config_file="$config"
            break
        fi
    done

    if [[ -z "$config_file" ]]; then
        echo "⚠ Tinyproxy config file not found"
        config_file="/etc/tinyproxy/tinyproxy.conf"
        mkdir -p "$(dirname "$config_file")"
        krun::install::tinyproxy::create_config "$config_file"
    else
        echo "✓ Found config file: $config_file"
        # Backup original config
        if [[ ! -f "${config_file}.bak" ]]; then
            cp "$config_file" "${config_file}.bak"
            echo "✓ Backed up original config"
        fi
    fi

    # Configure Tinyproxy
    krun::install::tinyproxy::configure "$config_file"

    # Start and enable service
    krun::install::tinyproxy::manage_service

    echo ""
    echo "=== Tinyproxy Installation Summary ==="
    echo "Config file: $config_file"
    echo "Default port: 8888"
    echo "Log file: /var/log/tinyproxy/tinyproxy.log"
    echo ""
    echo "Basic usage:"
    echo "  Configure your browser to use HTTP proxy:"
    echo "  Host: $(hostname -I | awk '{print $1}' 2>/dev/null || echo 'localhost')"
    echo "  Port: 8888"
    echo ""
    echo "Service management:"
    echo "  systemctl start tinyproxy    - Start service"
    echo "  systemctl stop tinyproxy     - Stop service"
    echo "  systemctl restart tinyproxy  - Restart service"
    echo "  systemctl status tinyproxy   - Check status"
    echo ""
    echo "Configuration file: $config_file"
    echo ""
    echo "Tinyproxy is ready to use!"
}

# Create basic Tinyproxy configuration
krun::install::tinyproxy::create_config() {
    local config_file="$1"

    cat >"$config_file" <<'EOF'
# Tinyproxy configuration file

# User and group to run as
User tinyproxy
Group tinyproxy

# Port to listen on
Port 8888

# Listen on all interfaces (comment out for localhost only)
# Listen 192.168.0.1

# Timeout for connections
Timeout 600

# Default error file location
DefaultErrorFile "/usr/share/tinyproxy/default.html"

# Log file
LogFile "/var/log/tinyproxy/tinyproxy.log"

# Log level (Critical, Error, Warning, Notice, Connect, Info)
LogLevel Info

# Maximum number of spare servers
MaxSpareServers 20

# Minimum number of spare servers
MinSpareServers 5

# Start servers
StartServers 10

# Maximum number of clients
MaxClients 100

# Maximum requests per child
MaxRequestsPerChild 0

# PID file
PidFile "/var/run/tinyproxy/tinyproxy.pid"

# Allow access from local networks (adjust as needed)
Allow 127.0.0.1
Allow 192.168.0.0/16
Allow 10.0.0.0/8
Allow 172.16.0.0/12

# Connect port restrictions (allow common ports)
ConnectPort 443
ConnectPort 563

# Via proxy header
ViaProxyName "tinyproxy"

# Disable via header
# DisableViaHeader Yes

# Filter configuration (optional)
# Filter "/etc/tinyproxy/filter"

# Anonymous proxy (remove client info)
# Anonymous "Host"
# Anonymous "Authorization"
# Anonymous "Cookie"

EOF

    echo "✓ Created basic configuration"
}

# Configure Tinyproxy
krun::install::tinyproxy::configure() {
    local config_file="$1"

    echo "Applying basic security configuration..."

    # Ensure log directory exists
    mkdir -p /var/log/tinyproxy
    chown tinyproxy:tinyproxy /var/log/tinyproxy 2>/dev/null || true

    # Ensure PID directory exists
    mkdir -p /var/run/tinyproxy
    chown tinyproxy:tinyproxy /var/run/tinyproxy 2>/dev/null || true

    # Set proper permissions
    chmod 644 "$config_file"

    echo "✓ Tinyproxy configured"
}

# Manage Tinyproxy service
krun::install::tinyproxy::manage_service() {
    echo "Managing Tinyproxy service..."

    if command -v systemctl >/dev/null 2>&1; then
        # Linux with systemd
        systemctl enable tinyproxy 2>/dev/null || true
        systemctl start tinyproxy 2>/dev/null || echo "⚠ Failed to start Tinyproxy service"

        # Check status
        if systemctl is-active tinyproxy >/dev/null 2>&1; then
            echo "✓ Tinyproxy service is running"
        else
            echo "⚠ Tinyproxy service is not running"
        fi

    elif [[ "$(uname)" == "Darwin" ]]; then
        # macOS with Homebrew
        if command -v brew >/dev/null 2>&1; then
            brew services start tinyproxy || echo "⚠ Failed to start Tinyproxy with brew services"
            echo "✓ Tinyproxy service configured for macOS"
        fi
    else
        echo "⚠ Cannot manage Tinyproxy service on this system"
        echo "You may need to start it manually: tinyproxy -c $config_file"
    fi
}

# run main
krun::install::tinyproxy::run "$@"
