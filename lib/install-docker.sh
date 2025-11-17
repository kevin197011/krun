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
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# run code
krun::install::docker::run() {
    echo -e "${BLUE}🐳 Installing Docker and Docker Compose...${NC}"

    # detect platform with better logic
    local platform='debian'
    if command -v dnf >/dev/null 2>&1; then
        platform='centos'
    elif command -v yum >/dev/null 2>&1; then
        platform='centos'
    elif command -v brew >/dev/null 2>&1; then
        platform='mac'
    elif command -v apt >/dev/null 2>&1; then
        platform='debian'
    fi

    echo -e "${GREEN}📊 Detected platform: ${platform}${NC}"

    # run platform specific installation
    eval "${FUNCNAME/::run/::${platform}}"

    echo -e "${GREEN}✅ Docker installation completed successfully!${NC}"
}

# debian/ubuntu installation
krun::install::docker::debian() {
    echo -e "${BLUE}🔧 Installing Docker on Debian/Ubuntu...${NC}"

    # remove old versions
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # update package index
    apt-get update

    # install dependencies
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        apt-transport-https \
        software-properties-common

    # create keyring directory
    install -m 0755 -d /etc/apt/keyrings

    # detect OS for correct GPG key
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" == "debian" ]]; then
            # Add Docker's official GPG key for Debian
            curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            chmod a+r /etc/apt/keyrings/docker.gpg

            # Add the repository to Apt sources
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
                tee /etc/apt/sources.list.d/docker.list >/dev/null
        else
            # Add Docker's official GPG key for Ubuntu
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            chmod a+r /etc/apt/keyrings/docker.gpg

            # Add the repository to Apt sources
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
                tee /etc/apt/sources.list.d/docker.list >/dev/null
        fi
    fi

    # update package index again
    apt-get update

    # install Docker packages
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    echo -e "${GREEN}✓ Docker packages installed${NC}"

    # configure and start services
    krun::install::docker::configure_service

    # run common setup
    krun::install::docker::common
}

# centos/rhel installation
krun::install::docker::centos() {
    echo -e "${BLUE}🔧 Installing Docker on CentOS/RHEL...${NC}"

    # remove old versions
    yum remove -y docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-engine \
        podman \
        runc 2>/dev/null || true

    # install dependencies
    if command -v dnf >/dev/null 2>&1; then
        dnf update -y
        dnf install -y yum-utils device-mapper-persistent-data lvm2

        # add Docker repository
        dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

        # install Docker packages
        dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    else
        yum update -y
        yum install -y yum-utils device-mapper-persistent-data lvm2

        # add Docker repository
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

        # install Docker packages
        yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi

    echo -e "${GREEN}✓ Docker packages installed${NC}"

    # configure and start services
    krun::install::docker::configure_service

    # run common setup
    krun::install::docker::common
}

# mac installation
krun::install::docker::mac() {
    echo -e "${BLUE}🔧 Installing Docker on macOS...${NC}"

    # remove old installations
    brew uninstall --cask docker --force 2>/dev/null || true
    brew uninstall --formula docker --force 2>/dev/null || true

    # install Docker Desktop for Mac
    if [[ $(uname -m) == "arm64" ]]; then
        echo -e "${YELLOW}Installing Docker Desktop for Apple Silicon...${NC}"
        brew install --cask docker
    else
        echo -e "${YELLOW}Installing Docker Desktop for Intel Mac...${NC}"
        brew install --cask docker
    fi

    echo -e "${GREEN}✓ Docker Desktop installed${NC}"
    echo -e "${YELLOW}⚠️  Please start Docker Desktop manually from Applications${NC}"

    # run common setup (without service configuration)
    krun::install::docker::common_mac
}

# configure Docker service
krun::install::docker::configure_service() {
    echo -e "${BLUE}🔧 Configuring Docker service...${NC}"

    # create docker group if it doesn't exist
    groupadd docker 2>/dev/null || true

    # start and enable Docker service
    systemctl start docker
    systemctl enable docker

    # configure Docker daemon for better performance
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

    # restart Docker to apply configuration
    systemctl restart docker

    echo -e "${GREEN}✓ Docker service configured and started${NC}"
}

# common setup for Linux
krun::install::docker::common() {
    echo -e "${BLUE}🔧 Running post-installation setup...${NC}"

    # wait for Docker to be ready
    sleep 3

    # verify installation
    if docker --version >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Docker installation verified${NC}"
        docker --version
    else
        echo -e "${RED}✗ Docker installation failed${NC}"
        exit 1
    fi

    if docker compose version >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Docker Compose installation verified${NC}"
        docker compose version
    else
        echo -e "${RED}✗ Docker Compose installation failed${NC}"
        exit 1
    fi

    # test Docker functionality
    echo -e "${BLUE}🧪 Testing Docker functionality...${NC}"
    if docker run --rm hello-world >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Docker test successful${NC}"
    else
        echo -e "${YELLOW}⚠️  Docker test failed, but installation appears complete${NC}"
    fi

    # show Docker system info
    echo -e "${BLUE}📊 Docker system information:${NC}"
    docker system info | grep -E "Server Version|Storage Driver|Cgroup Driver|Kernel Version" || true

    # add current user to docker group if running as non-root
    if [[ $EUID -ne 0 ]] && [[ -n "${SUDO_USER:-}" ]]; then
        usermod -aG docker "$SUDO_USER"
        echo -e "${GREEN}✓ Added user '$SUDO_USER' to docker group${NC}"
        echo -e "${YELLOW}⚠️  Please log out and back in for group changes to take effect${NC}"
    fi

    krun::install::docker::show_usage
}

# common setup for macOS
krun::install::docker::common_mac() {
    echo -e "${BLUE}🔧 Docker Desktop for macOS installed${NC}"

    # show installation info
    echo -e "${BLUE}📊 Installation completed:${NC}"
    echo "• Docker Desktop has been installed"
    echo "• Please start Docker Desktop from Applications folder"
    echo "• Docker commands will be available after starting Docker Desktop"

    krun::install::docker::show_usage
}

# show usage information
krun::install::docker::show_usage() {
    echo -e "${BLUE}🚀 Docker Installation Complete!${NC}"
    echo ""
    echo -e "${GREEN}Common Docker commands:${NC}"
    echo "  docker --version                 # Check Docker version"
    echo "  docker compose version           # Check Docker Compose version"
    echo "  docker run hello-world           # Test Docker installation"
    echo "  docker ps                        # List running containers"
    echo "  docker images                    # List Docker images"
    echo "  docker system prune              # Clean up unused resources"
    echo ""
    echo -e "${GREEN}Docker Compose examples:${NC}"
    echo "  docker compose up -d              # Start services in background"
    echo "  docker compose down               # Stop and remove services"
    echo "  docker compose logs               # View service logs"
    echo ""
    echo -e "${YELLOW}📚 Documentation:${NC}"
    echo "  https://docs.docker.com/"
    echo "  https://docs.docker.com/compose/"
    echo ""
}

# run main
krun::install::docker::run "$@"
