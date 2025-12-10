#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-rclone.sh | bash

# vars
rclone_version=${rclone_version:-latest}

# run code
krun::install::rclone::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::rclone::centos() {
    echo "Installing rclone on CentOS/RHEL..."

    [[ "$OSTYPE" != "darwin"* ]] && [[ $EUID -ne 0 ]] && echo "✗ Please run as root" && return 1

    yum install -y wget unzip || {
        echo "✗ Failed to install dependencies"
        return 1
    }
    krun::install::rclone::common
}

# debian code
krun::install::rclone::debian() {
    echo "Installing rclone on Debian/Ubuntu..."

    [[ "$OSTYPE" != "darwin"* ]] && [[ $EUID -ne 0 ]] && echo "✗ Please run as root" && return 1

    apt-get update && apt-get install -y wget unzip || {
        echo "✗ Failed to install dependencies"
        return 1
    }
    krun::install::rclone::common
}

# mac code
krun::install::rclone::mac() {
    echo "Installing rclone on macOS..."

    if command -v brew >/dev/null; then
        brew install rclone && echo "✓ rclone installed via Homebrew" && return
    fi

    echo "Homebrew not found, trying manual installation..."
    krun::install::rclone::common
}

# get latest version
krun::install::rclone::get_latest_version() {
    local version=$(curl -fsSL --connect-timeout 5 --max-time 10 https://api.github.com/repos/rclone/rclone/releases/latest 2>/dev/null | grep tag_name | head -n1 | cut -d '"' -f 4)
    if [[ -z "$version" ]]; then
        echo "Direct access failed, trying proxy..." >&2
        version=$(curl -fsSL --connect-timeout 5 --max-time 10 https://ghproxy.link/https://api.github.com/repos/rclone/rclone/releases/latest 2>/dev/null | grep tag_name | head -n1 | cut -d '"' -f 4)
    fi
    echo "${version:-v1.66.0}"
}

# get system info
krun::install::rclone::get_system_info() {
    local arch=$(uname -m)
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')

    [[ "$arch" == "x86_64" ]] && arch="amd64"
    [[ "$arch" == "aarch64" || "$arch" == "arm64" ]] && arch="arm64"
    [[ "$arch" != "amd64" && "$arch" != "arm64" ]] && arch="amd64"
    [[ "$os" != "darwin" ]] && os="linux"

    echo "$os $arch"
}

# common code
krun::install::rclone::common() {
    command -v rclone >/dev/null && {
        echo "✓ rclone already installed: $(rclone version | head -1)"
        return 0
    }

    local system_info=$(krun::install::rclone::get_system_info)
    local os=$(echo "$system_info" | cut -d' ' -f1)
    local arch=$(echo "$system_info" | cut -d' ' -f2)
    local tag="$rclone_version"
    [[ "$rclone_version" == "latest" ]] && tag=$(krun::install::rclone::get_latest_version)
    tag=${tag#v}

    echo "Downloading rclone ${tag} for ${os}/${arch}..."
    local temp_dir=$(mktemp -d)
    local download_url="https://github.com/rclone/rclone/releases/download/v${tag}/rclone-v${tag}-${os}-${arch}.zip"
    local download_success=false

    # Try direct access first
    if curl -fsSL --connect-timeout 10 --max-time 60 "$download_url" -o "${temp_dir}/rclone.zip" 2>/dev/null; then
        if [[ -f "${temp_dir}/rclone.zip" ]] && [[ -s "${temp_dir}/rclone.zip" ]]; then
            download_success=true
        fi
    fi

    # If direct access failed, try proxy
    if [[ "$download_success" == "false" ]]; then
        echo "Direct access failed, trying proxy..." >&2
        rm -f "${temp_dir}/rclone.zip"
        download_url="https://ghproxy.link/$download_url"
        if ! curl -fsSL --connect-timeout 10 --max-time 60 "$download_url" -o "${temp_dir}/rclone.zip" 2>/dev/null; then
            echo "✗ Failed to download rclone"
            rm -rf "$temp_dir"
            return 1
        fi
        if [[ ! -f "${temp_dir}/rclone.zip" ]] || [[ ! -s "${temp_dir}/rclone.zip" ]]; then
            echo "✗ Downloaded file from proxy is not valid"
            rm -rf "$temp_dir"
            return 1
        fi
    fi

    # Extract and install
    unzip -q "${temp_dir}/rclone.zip" -d "$temp_dir" || {
        echo "✗ Failed to extract rclone"
        rm -rf "$temp_dir"
        return 1
    }

    local binary_path="${temp_dir}/rclone-v${tag}-${os}-${arch}/rclone"
    [[ ! -f "$binary_path" ]] && {
        echo "✗ rclone binary not found in archive"
        rm -rf "$temp_dir"
        return 1
    }

    mkdir -p /usr/local/bin
    mv "$binary_path" /usr/local/bin/rclone
    chmod +x /usr/local/bin/rclone
    rm -rf "$temp_dir"

    # Verify installation
    if command -v rclone >/dev/null; then
        echo "✓ rclone installed successfully"
        rclone version | head -1
    else
        echo "✗ rclone installation failed"
        return 1
    fi
}

# run main
krun::install::rclone::run "$@"

