#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install-k9s.sh | bash

# vars
k9s_version=${k9s_version:-latest}

# run code
krun::install::k9s::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::k9s::centos() {
    echo "Installing k9s on CentOS/RHEL..."
    [[ "$(id -u)" -ne 0 ]] && echo "✗ Please run as root" && return 1

    if command -v dnf >/dev/null 2>&1; then
        dnf install -y curl tar
    else
        yum install -y curl tar
    fi
    krun::install::k9s::install_from_package rpm
}

# debian code
krun::install::k9s::debian() {
    echo "Installing k9s on Debian/Ubuntu..."
    [[ "$(id -u)" -ne 0 ]] && echo "✗ Please run as root" && return 1

    apt-get update
    apt-get install -y curl tar
    krun::install::k9s::install_from_package deb
}

# mac code
krun::install::k9s::mac() {
    echo "Installing k9s on macOS..."
    if command -v k9s >/dev/null 2>&1; then
        echo "✓ k9s already installed"
        krun::install::k9s::verify_installation
        return
    fi

    if command -v brew >/dev/null 2>&1; then
        brew install k9s
        echo "✓ k9s installed via Homebrew"
        krun::install::k9s::verify_installation
        return
    fi

    echo "Homebrew not found, installing from official tarball..."
    krun::install::k9s::install_from_tarball
}

krun::install::k9s::get_latest_version() {
    local version
    version=$(curl -fsSL --connect-timeout 5 --max-time 10 https://api.github.com/repos/derailed/k9s/releases/latest 2>/dev/null | grep tag_name | head -n1 | cut -d '"' -f 4)
    if [[ -z "$version" ]]; then
        version=$(curl -fsSL --connect-timeout 5 --max-time 10 https://ghproxy.link/https://api.github.com/repos/derailed/k9s/releases/latest 2>/dev/null | grep tag_name | head -n1 | cut -d '"' -f 4)
    fi
    echo "${version:-v0.51.0}"
}

krun::install::k9s::resolve_tag() {
    local tag="$k9s_version"
    [[ "$k9s_version" == "latest" ]] && tag=$(krun::install::k9s::get_latest_version)
    tag=${tag#v}
    echo "$tag"
}

krun::install::k9s::map_arch() {
    local machine arch tarball_arch
    machine=$(uname -m)

    case "$machine" in
        x86_64) arch="amd64"; tarball_arch="amd64" ;;
        aarch64 | arm64) arch="arm64"; tarball_arch="arm64" ;;
        armv7l | armv6l) arch="arm"; tarball_arch="armv7" ;;
        ppc64le) arch="ppc64le"; tarball_arch="ppc64le" ;;
        s390x) arch="s390x"; tarball_arch="s390x" ;;
        *) arch="amd64"; tarball_arch="amd64" ;;
    esac

    echo "$arch $tarball_arch"
}

krun::install::k9s::map_os() {
    local os tarball_os package_os
    os=$(uname -s | tr '[:upper:]' '[:lower:]')

    if [[ "$os" == "darwin" ]]; then
        tarball_os="Darwin"
        package_os=""
    else
        tarball_os="Linux"
        package_os="linux"
    fi

    echo "$tarball_os $package_os"
}

krun::install::k9s::download_file() {
    local download_url="$1"
    local downloaded_file="$2"

    if curl -fsSL --connect-timeout 10 --max-time 120 "$download_url" -o "$downloaded_file" 2>/dev/null; then
        [[ -f "$downloaded_file" ]] && [[ -s "$downloaded_file" ]] && return 0
    fi

    echo "Direct access failed, trying proxy..." >&2
    rm -f "$downloaded_file"
    curl -fsSL --connect-timeout 10 --max-time 120 "https://ghproxy.link/${download_url}" -o "$downloaded_file"
    [[ -f "$downloaded_file" ]] && [[ -s "$downloaded_file" ]]
}

krun::install::k9s::install_from_package() {
    local package_type="$1"
    local tag arch package_os asset_name temp_dir downloaded_file download_url

    tag=$(krun::install::k9s::resolve_tag)
    arch=$(krun::install::k9s::map_arch | cut -d' ' -f1)
    package_os=$(krun::install::k9s::map_os | cut -d' ' -f2)
    asset_name="k9s_${package_os}_${arch}.${package_type}"
    temp_dir=$(mktemp -d)
    downloaded_file="${temp_dir}/${asset_name}"
    download_url="https://github.com/derailed/k9s/releases/download/v${tag}/${asset_name}"

    echo "Downloading k9s ${tag} package ${asset_name}..."
    if ! krun::install::k9s::download_file "$download_url" "$downloaded_file"; then
        echo "Package download failed, falling back to tarball..." >&2
        rm -rf "$temp_dir"
        krun::install::k9s::install_from_tarball
        return
    fi

    if [[ "$package_type" == "deb" ]]; then
        dpkg -i "$downloaded_file" || apt-get install -f -y
    else
        rpm -Uvh "$downloaded_file"
    fi

    rm -rf "$temp_dir"
    echo "✓ k9s installed from ${package_type} package"
    krun::install::k9s::verify_installation
}

krun::install::k9s::install_from_tarball() {
    local tag tarball_os tarball_arch asset_name temp_dir downloaded_file download_url install_dir

    tag=$(krun::install::k9s::resolve_tag)
    tarball_os=$(krun::install::k9s::map_os | cut -d' ' -f1)
    tarball_arch=$(krun::install::k9s::map_arch | cut -d' ' -f2)
    asset_name="k9s_${tarball_os}_${tarball_arch}.tar.gz"
    temp_dir=$(mktemp -d)
    downloaded_file="${temp_dir}/k9s.tar.gz"
    download_url="https://github.com/derailed/k9s/releases/download/v${tag}/${asset_name}"
    install_dir="/usr/local/bin"

    echo "Downloading k9s ${tag} tarball ${asset_name}..."
    if ! krun::install::k9s::download_file "$download_url" "$downloaded_file"; then
        echo "✗ Failed to download k9s"
        rm -rf "$temp_dir"
        return 1
    fi

    if ! gzip -t "$downloaded_file" 2>/dev/null; then
        echo "✗ Downloaded file is not a valid tarball"
        rm -rf "$temp_dir"
        return 1
    fi

    tar -xzf "$downloaded_file" -C "$temp_dir"
    [[ ! -f "${temp_dir}/k9s" ]] && echo "✗ k9s binary not found in archive" && rm -rf "$temp_dir" && return 1

    install -m 755 "${temp_dir}/k9s" "${install_dir}/k9s"
    rm -rf "$temp_dir"
    echo "✓ k9s installed from tarball"
    krun::install::k9s::verify_installation
}

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
