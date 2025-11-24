#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-node_exporter.sh | bash

# vars
node_exporter_version=${node_exporter_version:-latest}

# run code
krun::install::node_exporter::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::node_exporter::centos() {
    echo "Installing Node Exporter on CentOS/RHEL..."
    [[ "$(id -u)" -ne 0 ]] && echo "✗ Please run as root" && return 1

    systemctl stop node_exporter 2>/dev/null || true
    yum install -y wget tar || {
        echo "✗ Failed to install dependencies"
        return 1
    }
    krun::install::node_exporter::common
}

# debian code
krun::install::node_exporter::debian() {
    echo "Installing Node Exporter on Debian/Ubuntu..."
    [[ "$(id -u)" -ne 0 ]] && echo "✗ Please run as root" && return 1

    systemctl stop node_exporter 2>/dev/null || true
    apt-get update && apt-get install -y wget tar || {
        echo "✗ Failed to install dependencies"
        return 1
    }
    krun::install::node_exporter::common
}

# mac code
krun::install::node_exporter::mac() {
    echo "Installing Node Exporter on macOS..."
    command -v node_exporter >/dev/null && echo "✓ Node Exporter already installed" && return

    if command -v brew >/dev/null; then
        brew install node_exporter && echo "✓ Node Exporter installed via Homebrew" && return
    fi

    echo "Homebrew not found, trying manual installation..."
    krun::install::node_exporter::manual_install
}

# get latest version
krun::install::node_exporter::get_latest_version() {
    local version=$(curl -fsSL --connect-timeout 5 --max-time 10 https://api.github.com/repos/prometheus/node_exporter/releases/latest 2>/dev/null | grep tag_name | head -n1 | cut -d '"' -f 4)
    if [[ -z "$version" ]]; then
        echo "Direct access failed, trying proxy..." >&2
        version=$(curl -fsSL --connect-timeout 5 --max-time 10 https://ghproxy.link/https://api.github.com/repos/prometheus/node_exporter/releases/latest 2>/dev/null | grep tag_name | head -n1 | cut -d '"' -f 4)
    fi
    echo "${version:-v1.9.0}"
}

# get system info
krun::install::node_exporter::get_system_info() {
    local arch=$(uname -m)
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')

    [[ "$arch" == "x86_64" ]] && arch="amd64"
    [[ "$arch" == "aarch64" || "$arch" == "arm64" ]] && arch="arm64"
    [[ "$arch" != "amd64" && "$arch" != "arm64" ]] && arch="amd64"
    [[ "$os" != "darwin" ]] && os="linux"

    echo "$os $arch"
}

# manual installation
krun::install::node_exporter::manual_install() {
    echo "Manual installation not supported for Node Exporter"
    echo "Please install via package manager or Homebrew"
    return 1
}

# common code
krun::install::node_exporter::common() {
    echo "Installing Node Exporter..."
    [[ "$(id -u)" -ne 0 ]] && echo "✗ Please run as root" && return 1

    local system_info=$(krun::install::node_exporter::get_system_info)
    local os=$(echo "$system_info" | cut -d' ' -f1)
    local arch=$(echo "$system_info" | cut -d' ' -f2)
    local tag="$node_exporter_version"
    [[ "$node_exporter_version" == "latest" ]] && tag=$(krun::install::node_exporter::get_latest_version)
    tag=${tag#v}

    echo "Downloading Node Exporter ${tag} for ${os}/${arch}..."
    local temp_dir=$(mktemp -d)
    local download_url="https://github.com/prometheus/node_exporter/releases/download/v${tag}/node_exporter-${tag}.${os}-${arch}.tar.gz"
    local downloaded_file="${temp_dir}/node_exporter.tar.gz"
    local download_success=false

    # Try direct access first
    if curl -fsSL --connect-timeout 10 --max-time 60 "$download_url" -o "$downloaded_file" 2>/dev/null; then
        # Verify downloaded file is valid
        if [[ -f "$downloaded_file" ]] && [[ -s "$downloaded_file" ]] && gzip -t "$downloaded_file" 2>/dev/null; then
            download_success=true
        fi
    fi

    # If direct access failed, try proxy
    if [[ "$download_success" == "false" ]]; then
        echo "Direct access failed, trying proxy..." >&2
        rm -f "$downloaded_file"
        download_url="https://ghproxy.link/$download_url"
        if ! curl -fsSL --connect-timeout 10 --max-time 60 "$download_url" -o "$downloaded_file" 2>/dev/null; then
            echo "✗ Failed to download Node Exporter"
            rm -rf "$temp_dir"
            return 1
        fi
        # Verify proxy download is valid
        if [[ ! -f "$downloaded_file" ]] || [[ ! -s "$downloaded_file" ]] || ! gzip -t "$downloaded_file" 2>/dev/null; then
            echo "✗ Downloaded file from proxy is not valid"
            if [[ -f "$downloaded_file" ]]; then
                echo "File size: $(stat -c%s "$downloaded_file" 2>/dev/null || stat -f%z "$downloaded_file" 2>/dev/null) bytes"
                echo "First 200 bytes:"
                head -c 200 "$downloaded_file" 2>/dev/null | cat
                echo ""
            fi
            rm -rf "$temp_dir"
            return 1
        fi
    fi

    mkdir -p /opt/node_exporter &&
        tar -xzf "$downloaded_file" -C "$temp_dir" &&
        mv "${temp_dir}/node_exporter-${tag}.${os}-${arch}/node_exporter" "/opt/node_exporter/" &&
        chmod +x "/opt/node_exporter/node_exporter" &&
        rm -rf "$temp_dir" &&
        echo "✓ Node Exporter installed"

    krun::install::node_exporter::create_service
    krun::install::node_exporter::verify_installation
}

# create systemd service
krun::install::node_exporter::create_service() {
    cat >/etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=root
ExecStart=/opt/node_exporter/node_exporter
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload || {
        echo "✗ Failed to reload systemd daemon"
        return 1
    }

    systemctl enable node_exporter || {
        echo "✗ Failed to enable node_exporter service"
        return 1
    }

    systemctl start node_exporter || {
        echo "⚠ Failed to start node_exporter service"
        echo "Service status:"
        systemctl status node_exporter --no-pager -l || true
        echo ""
        echo "Recent logs:"
        journalctl -u node_exporter -n 20 --no-pager || true
        return 1
    }

    echo "✓ Node Exporter service created and started"
}

# verify installation
krun::install::node_exporter::verify_installation() {
    command -v /opt/node_exporter/node_exporter >/dev/null && echo "✓ Node Exporter binary found" || {
        echo "✗ Node Exporter binary not found"
        return 1
    }

    if systemctl is-active node_exporter >/dev/null 2>&1; then
        echo "✓ Node Exporter service is running"
    else
        echo "⚠ Node Exporter service not running"
        echo ""
        echo "Service status:"
        systemctl status node_exporter --no-pager -l || true
        echo ""
        echo "Recent logs:"
        journalctl -u node_exporter -n 20 --no-pager || true
        echo ""
        echo "Trying to start service..."
        systemctl start node_exporter && echo "✓ Service started successfully" || echo "✗ Failed to start service"
    fi

    echo ""
    echo "Access metrics at http://localhost:9100/metrics"
}

# run main
krun::install::node_exporter::run "$@"
