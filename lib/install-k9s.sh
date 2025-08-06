#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-k9s.sh | bash

# vars
k9s_version=${k9s_version:-latest}

# run code
krun::install::k9s::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::k9s::centos() {
    echo "Installing k9s on CentOS/RHEL..."
    yum install -y curl
    krun::install::k9s::common
}

# debian code
krun::install::k9s::debian() {
    echo "Installing k9s on Debian/Ubuntu..."
    apt-get update
    apt-get install -y curl
    krun::install::k9s::common
}

# mac code
krun::install::k9s::mac() {
    echo "Installing k9s on macOS..."
    if command -v brew >/dev/null 2>&1; then
        brew install k9s
        echo "✓ k9s installed via Homebrew"
        krun::install::k9s::verify_installation
        return
    fi
    echo "Homebrew not found, installing manually..."
    krun::install::k9s::common
}

# get latest version
krun::install::k9s::get_latest_version() {
    curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | head -n1 | cut -d '"' -f 4
}

# get system info
krun::install::k9s::get_system_info() {
    local arch=$(uname -m)
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')

    # Map architecture
    [[ "$arch" == "x86_64" ]] && arch="x86_64"
    [[ "$arch" == "aarch64" || "$arch" == "arm64" ]] && arch="arm64"
    [[ "$arch" != "x86_64" && "$arch" != "arm64" ]] && arch="x86_64"

    # Map OS
    [[ "$os" != "darwin" ]] && os="linux"

    echo "$os $arch"
}

# common code
krun::install::k9s::common() {
    echo "Installing k9s Kubernetes CLI..."

    # Get system info and version
    local system_info=$(krun::install::k9s::get_system_info)
    local os=$(echo "$system_info" | cut -d' ' -f1)
    local arch=$(echo "$system_info" | cut -d' ' -f2)
    local tag="$k9s_version"

    [[ "$k9s_version" == "latest" ]] && tag=$(krun::install::k9s::get_latest_version)
    tag=${tag#v} # Remove 'v' prefix

    echo "Downloading k9s ${tag} for ${os}/${arch}..."

    # Download and install
    local temp_dir=$(mktemp -d)
    local download_url="https://github.com/derailed/k9s/releases/download/v${tag}/k9s_${os}_${arch}.tar.gz"

    curl -fsSL "$download_url" -o "${temp_dir}/k9s.tar.gz" || {
        echo "✗ Failed to download k9s"
        rm -rf "$temp_dir"
        return 1
    }

    tar -xzf "${temp_dir}/k9s.tar.gz" -C "$temp_dir" &&
        mv "${temp_dir}/k9s" "/usr/local/bin/" &&
        chmod +x "/usr/local/bin/k9s" &&
        rm -rf "$temp_dir" &&
        echo "✓ k9s installed successfully"

    krun::install::k9s::verify_installation
}

# Verify k9s installation
krun::install::k9s::verify_installation() {
    echo "Verifying k9s installation..."

    if command -v k9s >/dev/null 2>&1; then
        echo "✓ k9s command is available"
        k9s version
        echo ""
        echo "Common commands:"
        echo "  k9s                           - Start k9s"
        echo "  k9s -n <namespace>            - Start in specific namespace"
        echo "  k9s --context <context>       - Use specific kubeconfig context"
        echo "  k9s --help                    - Show help"
        echo ""
        echo "Example: k9s -n default"
        echo "k9s is ready to use!"
    else
        echo "✗ k9s command not found"
        return 1
    fi
}

# run main
krun::install::k9s::run "$@"
