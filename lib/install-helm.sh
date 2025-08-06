#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-helm.sh | bash

# vars
helm_version=${helm_version:-latest}

# run code
krun::install::helm::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::helm::centos() {
    echo "Installing Helm on CentOS/RHEL..."
    yum install -y curl
    krun::install::helm::common
}

# debian code
krun::install::helm::debian() {
    echo "Installing Helm on Debian/Ubuntu..."
    apt-get update
    apt-get install -y curl
    krun::install::helm::common
}

# mac code
krun::install::helm::mac() {
    echo "Installing Helm on macOS..."
    if command -v brew >/dev/null 2>&1; then
        brew install helm
        echo "✓ Helm installed via Homebrew"
        krun::install::helm::verify_installation
        return
    fi
    echo "Homebrew not found, installing manually..."
    krun::install::helm::common
}

# get latest version
krun::install::helm::get_latest_version() {
    curl -fsSL https://api.github.com/repos/helm/helm/releases/latest | grep tag_name | head -n1 | cut -d '"' -f 4
}

# get system info
krun::install::helm::get_system_info() {
    local arch=$(uname -m)
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')

    # Map architecture
    [[ "$arch" == "x86_64" ]] && arch="amd64"
    [[ "$arch" == "aarch64" || "$arch" == "arm64" ]] && arch="arm64"
    [[ "$arch" == "armv7l" ]] && arch="arm"
    [[ "$arch" != "amd64" && "$arch" != "arm64" && "$arch" != "arm" ]] && arch="amd64"

    # Map OS
    [[ "$os" != "darwin" ]] && os="linux"

    echo "$os $arch"
}

# common code
krun::install::helm::common() {
    echo "Installing Helm package manager..."

    # Get system info and version
    local system_info=$(krun::install::helm::get_system_info)
    local os=$(echo "$system_info" | cut -d' ' -f1)
    local arch=$(echo "$system_info" | cut -d' ' -f2)
    local tag="$helm_version"

    [[ "$helm_version" == "latest" ]] && tag=$(krun::install::helm::get_latest_version)
    tag=${tag#v} # Remove 'v' prefix

    echo "Downloading Helm ${tag} for ${os}/${arch}..."

    # Download and install
    local temp_dir=$(mktemp -d)
    local download_url="https://get.helm.sh/helm-v${tag}-${os}-${arch}.tar.gz"

    curl -fsSL "$download_url" -o "${temp_dir}/helm.tar.gz" || {
        echo "Trying alternative download method..."
        curl -fsSL "https://github.com/helm/helm/releases/download/v${tag}/helm-v${tag}-${os}-${arch}.tar.gz" -o "${temp_dir}/helm.tar.gz" || {
            echo "✗ Failed to download Helm"
            rm -rf "$temp_dir"
            return 1
        }
    }

    tar -xzf "${temp_dir}/helm.tar.gz" -C "$temp_dir" &&
        mv "${temp_dir}/${os}-${arch}/helm" "/usr/local/bin/" &&
        chmod +x "/usr/local/bin/helm" &&
        rm -rf "$temp_dir" &&
        echo "✓ Helm installed successfully"

    krun::install::helm::install_plugins
    krun::install::helm::verify_installation
}

# Install common Helm plugins
krun::install::helm::install_plugins() {
    echo "Installing common Helm plugins..."
    local plugins=(
        "https://github.com/databus23/helm-diff"
        "https://github.com/jkroepke/helm-secrets"
        "https://github.com/aslafy-z/helm-git"
    )

    for plugin in "${plugins[@]}"; do
        helm plugin install "$plugin" 2>/dev/null || echo "⚠ Plugin installation failed: $plugin"
    done
}

# Verify Helm installation
krun::install::helm::verify_installation() {
    echo "Verifying Helm installation..."

    if command -v helm >/dev/null 2>&1; then
        echo "✓ helm command is available"
        helm version --short
        echo ""
        echo "Common commands:"
        echo "  helm repo add <name> <url>    - Add chart repository"
        echo "  helm install <name> <chart>   - Install chart"
        echo "  helm list                      - List releases"
        echo "  helm plugin list              - List plugins"
        echo ""
        echo "Example: helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx"
        echo "Helm is ready to use!"
    else
        echo "✗ helm command not found"
        return 1
    fi
}

# run main
krun::install::helm::run "$@"
