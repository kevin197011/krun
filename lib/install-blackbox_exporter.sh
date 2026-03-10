#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-blackbox_exporter.sh | bash

# vars
blackbox_exporter_version=${blackbox_exporter_version:-latest}

# run code
krun::install::blackbox_exporter::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::blackbox_exporter::centos() {
    echo "Installing Blackbox Exporter on CentOS/RHEL..."
    [[ "$(id -u)" -ne 0 ]] && echo "✗ Please run as root" && return 1

    systemctl stop blackbox_exporter 2>/dev/null || true
    yum install -y wget tar || { echo "✗ Failed to install dependencies"; return 1; }
    krun::install::blackbox_exporter::common
}

# debian code
krun::install::blackbox_exporter::debian() {
    echo "Installing Blackbox Exporter on Debian/Ubuntu..."
    [[ "$(id -u)" -ne 0 ]] && echo "✗ Please run as root" && return 1

    systemctl stop blackbox_exporter 2>/dev/null || true
    apt-get update && apt-get install -y wget tar || { echo "✗ Failed to install dependencies"; return 1; }
    krun::install::blackbox_exporter::common
}

# mac code
krun::install::blackbox_exporter::mac() {
    echo "Installing Blackbox Exporter on macOS..."
    command -v blackbox_exporter >/dev/null && echo "✓ Blackbox Exporter already installed" && return

    if command -v brew >/dev/null; then
        brew install blackbox_exporter && echo "✓ Blackbox Exporter installed via Homebrew" && return
    fi

    echo "Homebrew not found, trying manual installation..."
    krun::install::blackbox_exporter::manual_install
}

krun::install::blackbox_exporter::get_latest_version() {
    local version
    version=$(curl -fsSL --connect-timeout 5 --max-time 10 https://api.github.com/repos/prometheus/blackbox_exporter/releases/latest 2>/dev/null | grep tag_name | head -n1 | cut -d '"' -f 4)
    if [[ -z "$version" ]]; then
        version=$(curl -fsSL --connect-timeout 5 --max-time 10 https://ghproxy.link/https://api.github.com/repos/prometheus/blackbox_exporter/releases/latest 2>/dev/null | grep tag_name | head -n1 | cut -d '"' -f 4)
    fi
    echo "${version:-v0.28.0}"
}

krun::install::blackbox_exporter::get_system_info() {
    local arch os
    arch=$(uname -m)
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    [[ "$arch" == "x86_64" ]] && arch="amd64"
    [[ "$arch" == "aarch64" || "$arch" == "arm64" ]] && arch="arm64"
    [[ "$arch" != "amd64" && "$arch" != "arm64" ]] && arch="amd64"
    [[ "$os" != "darwin" ]] && os="linux"
    echo "$os $arch"
}

krun::install::blackbox_exporter::manual_install() {
    echo "Manual installation not supported for Blackbox Exporter"
    echo "Please install via package manager or Homebrew"
    return 1
}

krun::install::blackbox_exporter::common() {
    echo "Installing Blackbox Exporter..."
    [[ "$(id -u)" -ne 0 ]] && echo "✗ Please run as root" && return 1

    local system_info os arch tag
    system_info=$(krun::install::blackbox_exporter::get_system_info)
    os=$(echo "$system_info" | cut -d' ' -f1)
    arch=$(echo "$system_info" | cut -d' ' -f2)
    tag="$blackbox_exporter_version"
    [[ "$blackbox_exporter_version" == "latest" ]] && tag=$(krun::install::blackbox_exporter::get_latest_version)
    tag=${tag#v}

    echo "Downloading Blackbox Exporter ${tag} for ${os}/${arch}..."
    local temp_dir downloaded_file download_url download_success
    temp_dir=$(mktemp -d)
    download_url="https://github.com/prometheus/blackbox_exporter/releases/download/v${tag}/blackbox_exporter-${tag}.${os}-${arch}.tar.gz"
    downloaded_file="${temp_dir}/blackbox_exporter.tar.gz"
    download_success=false

    if curl -fsSL --connect-timeout 10 --max-time 60 "$download_url" -o "$downloaded_file" 2>/dev/null; then
        if [[ -f "$downloaded_file" ]] && [[ -s "$downloaded_file" ]] && gzip -t "$downloaded_file" 2>/dev/null; then
            download_success=true
        fi
    fi

    if [[ "$download_success" == "false" ]]; then
        echo "Direct access failed, trying proxy..." >&2
        rm -f "$downloaded_file"
        download_url="https://ghproxy.link/$download_url"
        if ! curl -fsSL --connect-timeout 10 --max-time 60 "$download_url" -o "$downloaded_file" 2>/dev/null; then
            echo "✗ Failed to download Blackbox Exporter"
            rm -rf "$temp_dir"
            return 1
        fi
        if [[ ! -f "$downloaded_file" ]] || [[ ! -s "$downloaded_file" ]] || ! gzip -t "$downloaded_file" 2>/dev/null; then
            echo "✗ Downloaded file is not valid"
            rm -rf "$temp_dir"
            return 1
        fi
    fi

    mkdir -p /opt/blackbox_exporter
    tar -xzf "$downloaded_file" -C "$temp_dir"
    local extracted_dir="${temp_dir}/blackbox_exporter-${tag}.${os}-${arch}"
    [[ ! -d "$extracted_dir" ]] && extracted_dir=$(find "$temp_dir" -maxdepth 1 -type d -name "blackbox_exporter*" | head -1)
    mv "${extracted_dir}/blackbox_exporter" /opt/blackbox_exporter/
    [[ -f "${extracted_dir}/blackbox.yml" ]] && mv "${extracted_dir}/blackbox.yml" /opt/blackbox_exporter/
    chmod 755 /opt/blackbox_exporter
    chmod 755 /opt/blackbox_exporter/blackbox_exporter
    chown -R root:root /opt/blackbox_exporter
    rm -rf "$temp_dir"
    echo "✓ Blackbox Exporter installed"

    if [[ ! -f /opt/blackbox_exporter/blackbox.yml ]]; then
        krun::install::blackbox_exporter::write_default_config
    fi

    if [[ ! -x /opt/blackbox_exporter/blackbox_exporter ]]; then
        chmod +x /opt/blackbox_exporter/blackbox_exporter
    fi

    if command -v getenforce >/dev/null 2>&1 && [[ "$(getenforce)" != "Disabled" ]]; then
        command -v restorecon >/dev/null 2>&1 && restorecon -R /opt/blackbox_exporter || true
        command -v chcon >/dev/null 2>&1 && chcon -t bin_t /opt/blackbox_exporter/blackbox_exporter 2>/dev/null || true
    fi

    krun::install::blackbox_exporter::create_service
    krun::install::blackbox_exporter::verify_installation
}

krun::install::blackbox_exporter::write_default_config() {
    cat > /opt/blackbox_exporter/blackbox.yml <<'EOF'
---
modules:
  http_2xx_json:
    prober: http
    http:
      headers:
        Accept: 'application/json'
        User-Agent: 'blackbox-monitoring'
      preferred_ip_protocol: "ip4"
  http_2xx:
    prober: http
    http:
      preferred_ip_protocol: "ip4"
  http_post_2xx:
    prober: http
    http:
      method: POST
  tcp_connect:
    prober: tcp
  pop3s_banner:
    prober: tcp
    tcp:
      query_response:
      - expect: "^+OK"
      tls: true
      tls_config:
        insecure_skip_verify: false
  grpc:
    prober: grpc
    grpc:
      tls: true
      preferred_ip_protocol: "ip4"
  grpc_plain:
    prober: grpc
    grpc:
      tls: false
      service: "service1"
  ssh_banner:
    prober: tcp
    tcp:
      query_response:
      - expect: "^SSH-2.0-"
      - send: "SSH-2.0-blackbox-ssh-check"
  irc_banner:
    prober: tcp
    tcp:
      query_response:
      - send: "NICK prober"
      - send: "USER prober prober prober :prober"
      - expect: "PING :([^ ]+)"
        send: "PONG ${1}"
      - expect: "^:[^ ]+ 001"
  icmp:
    prober: icmp
  icmp_ttl5:
    prober: icmp
    timeout: 5s
    icmp:
      ttl: 5
EOF
    chown root:root /opt/blackbox_exporter/blackbox.yml
    echo "✓ Default blackbox.yml created"
}

krun::install::blackbox_exporter::create_service() {
    if [[ ! -f /opt/blackbox_exporter/blackbox_exporter ]]; then
        echo "✗ Binary not found at /opt/blackbox_exporter/blackbox_exporter"
        return 1
    fi
    [[ ! -x /opt/blackbox_exporter/blackbox_exporter ]] && chmod +x /opt/blackbox_exporter/blackbox_exporter

    cat > /etc/systemd/system/blackbox_exporter.service <<EOF
[Unit]
Description=Blackbox Exporter
After=network.target

[Service]
User=root
ExecStart=/opt/blackbox_exporter/blackbox_exporter --config.file=/opt/blackbox_exporter/blackbox.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload || { echo "✗ Failed to reload systemd"; return 1; }
    systemctl enable blackbox_exporter || true
    systemctl start blackbox_exporter || {
        echo "⚠ Failed to start blackbox_exporter"
        systemctl status blackbox_exporter --no-pager -l || true
        return 1
    }
    echo "✓ Blackbox Exporter service created and started"
}

krun::install::blackbox_exporter::verify_installation() {
    command -v /opt/blackbox_exporter/blackbox_exporter >/dev/null && echo "✓ Blackbox Exporter binary found" || { echo "✗ Binary not found"; return 1; }

    if systemctl is-active blackbox_exporter >/dev/null 2>&1; then
        echo "✓ Blackbox Exporter service is running"
    else
        echo "⚠ Blackbox Exporter service not running"
        systemctl status blackbox_exporter --no-pager -l || true
        systemctl start blackbox_exporter && echo "✓ Service started" || true
    fi
    echo ""
    echo "Probe UI: http://localhost:9115"
    echo "Metrics:  http://localhost:9115/metrics"
}

# run main
krun::install::blackbox_exporter::run "$@"
