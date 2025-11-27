#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-docker.sh | bash

# vars

# run code
krun::install::docker::run() {
    echo "Installing Docker and Docker Compose..."

    local platform='debian'
    command -v dnf >/dev/null && platform='centos'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'

    echo "Detected platform: $platform"
    eval "${FUNCNAME/::run/::${platform}}"
    echo "✓ Docker installation completed"
}

# debian/ubuntu installation
krun::install::docker::debian() {
    echo "Installing Docker on Debian/Ubuntu..."

    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    apt-get update

    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ca-certificates curl gnupg lsb-release apt-transport-https software-properties-common

    install -m 0755 -d /etc/apt/keyrings

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        local gpg_url="https://download.docker.com/linux/ubuntu/gpg"
        [[ "$ID" == "debian" ]] && gpg_url="https://download.docker.com/linux/debian/gpg"

        curl -fsSL "$gpg_url" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg

        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ID $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
            tee /etc/apt/sources.list.d/docker.list >/dev/null
    fi

    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    krun::install::docker::configure_service
    krun::install::docker::common
}

# centos/rhel installation
krun::install::docker::centos() {
    echo "Installing Docker on CentOS/RHEL..."

    yum remove -y docker docker-client docker-client-latest docker-common \
        docker-latest docker-latest-logrotate docker-logrotate docker-engine podman runc 2>/dev/null || true

    if command -v dnf >/dev/null; then
        dnf update -y
        dnf install -y yum-utils device-mapper-persistent-data lvm2
        dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    else
        yum update -y
        yum install -y yum-utils device-mapper-persistent-data lvm2
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi

    krun::install::docker::configure_service
    krun::install::docker::common
}

# mac installation
krun::install::docker::mac() {
    echo "Installing Docker on macOS..."

    brew uninstall --cask docker --force 2>/dev/null || true
    brew uninstall --formula docker --force 2>/dev/null || true
    brew install --cask docker

    echo "✓ Docker Desktop installed"
    echo "⚠ Please start Docker Desktop manually from Applications"
    krun::install::docker::common_mac
}

# configure Docker service
krun::install::docker::configure_service() {
    echo "Configuring Docker service..."

    groupadd docker 2>/dev/null || true
    systemctl start docker
    systemctl enable docker

    mkdir -p /etc/docker
    cat >/etc/docker/daemon.json <<'EOF'
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "exec-opts": ["native.cgroupdriver=systemd"],
    "live-restore": true,
    "userland-proxy": false,
    "experimental": false,
    "metrics-addr": "127.0.0.1:9323",
    "default-address-pools": [
        {
            "base": "172.30.0.0/16",
            "size": 24
        }
    ]
}
EOF

    systemctl restart docker
    echo "✓ Docker service configured and started"
}

# common setup for Linux
krun::install::docker::common() {
    echo "Verifying installation..."
    sleep 3

    docker --version || {
        echo "✗ Docker installation failed"
        return 1
    }

    docker compose version || {
        echo "✗ Docker Compose installation failed"
        return 1
    }

    docker run --rm hello-world >/dev/null 2>&1 && echo "✓ Docker test successful" || echo "⚠ Docker test failed"

    if [[ $EUID -ne 0 ]] && [[ -n "${SUDO_USER:-}" ]]; then
        usermod -aG docker "$SUDO_USER"
        echo "✓ Added user '$SUDO_USER' to docker group"
        echo "⚠ Please log out and back in for group changes to take effect"
    fi
}

# common setup for macOS
krun::install::docker::common_mac() {
    echo "Docker Desktop for macOS installed"
    echo "Please start Docker Desktop from Applications folder"
}

# run main
krun::install::docker::run "$@"
