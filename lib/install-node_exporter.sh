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

# run code
krun::install::node_exporter::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::node_exporter::centos() {
    systemctl stop node_exporter || true
    # Define variables
    NODE_EXPORTER_VERSION="1.9.0" # Change the version as needed
    NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
    INSTALL_DIR="/opt/node_exporter"
    SERVICE_FILE="/etc/systemd/system/node_exporter.service"

    # Check if the script is run as root
    [[ "$(id -u)" -ne 0 ]] && echo "Please run this script as root!" && exit 1

    # Create installation directory
    echo "Creating installation directory: ${INSTALL_DIR}"
    mkdir -p "${INSTALL_DIR}"

    # Download and extract node_exporter
    echo "Downloading node_exporter..."
    yum install wget -y
    cd /tmp
    wget -q "${NODE_EXPORTER_URL}" -O node_exporter.tar.gz
    [[ $? -ne 0 ]] && echo "Download failed. Please check your network connection or the URL." && exit 1

    echo "Extracting node_exporter..."
    tar -xzf node_exporter.tar.gz -C "${INSTALL_DIR}" --strip-components=1

    # Clean up temporary files
    rm -f node_exporter.tar.gz

    # Create systemd service file
    echo "Creating systemd service file..."
    cat <<EOF | tee "${SERVICE_FILE}" >/dev/null
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=root
ExecStart=${INSTALL_DIR}/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd configuration
    echo "Reloading systemd configuration..."
    systemctl daemon-reload

    # Start and enable node_exporter service
    echo "Starting node_exporter service..."
    systemctl start node_exporter
    systemctl enable node_exporter

    # Check service status
    echo "Checking node_exporter service status..."
    systemctl status node_exporter --no-pager

    # Output completion message
    echo "Installation complete!"
    echo "node_exporter has been started and enabled to run on boot."
    echo "Access metrics at http://localhost:9100/metrics."
    krun::install::node_exporter::common
}

# debian code
krun::install::node_exporter::debian() {
    krun::install::node_exporter::common
}

# mac code
krun::install::node_exporter::mac() {
    krun::install::node_exporter::common
}

# common code
krun::install::node_exporter::common() {
    systemctl status node_exporter
}

# run main
krun::install::node_exporter::run "$@"
