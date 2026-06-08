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
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::helm::centos() {
    echo "Installing Helm on CentOS/RHEL..."
    [[ "$(id -u)" -ne 0 ]] && echo "✗ Please run as root" && return 1

    if command -v dnf >/dev/null 2>&1; then
        dnf install -y curl tar
    else
        yum install -y curl tar
    fi
    krun::install::helm::common
}

# debian code
krun::install::helm::debian() {
    echo "Installing Helm on Debian/Ubuntu..."
    [[ "$(id -u)" -ne 0 ]] && echo "✗ Please run as root" && return 1

    apt-get update
    apt-get install -y curl tar
    krun::install::helm::common
}

# mac code
krun::install::helm::mac() {
    echo "Installing Helm on macOS..."
    if command -v helm >/dev/null 2>&1; then
        echo "✓ Helm already installed"
        krun::install::helm::verify_installation
        return
    fi

    if command -v brew >/dev/null 2>&1; then
        brew install helm
        echo "✓ Helm installed via Homebrew"
        krun::install::helm::verify_installation
        return
    fi

    echo "Homebrew not found, installing manually..."
    krun::install::helm::common
}

krun::install::helm::get_latest_version() {
    local version
    version=$(curl -fsSL --connect-timeout 5 --max-time 10 https://api.github.com/repos/helm/helm/releases/latest 2>/dev/null | grep tag_name | head -n1 | cut -d '"' -f 4)
    if [[ -z "$version" ]]; then
        version=$(curl -fsSL --connect-timeout 5 --max-time 10 https://ghproxy.link/https://api.github.com/repos/helm/helm/releases/latest 2>/dev/null | grep tag_name | head -n1 | cut -d '"' -f 4)
    fi
    echo "${version:-v4.2.0}"
}

krun::install::helm::get_system_info() {
    local arch os
    arch=$(uname -m)
    os=$(uname -s | tr '[:upper:]' '[:lower:]')

    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64 | arm64) arch="arm64" ;;
        armv7l | armv6l) arch="arm" ;;
        *) arch="amd64" ;;
    esac

    [[ "$os" != "darwin" ]] && os="linux"
    echo "$os $arch"
}

krun::install::helm::install_dir() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo "/usr/local/bin"
        return
    fi

    if [[ "$(id -u)" -eq 0 ]]; then
        echo "/usr/bin"
        return
    fi

    echo "/usr/local/bin"
}

krun::install::helm::download_file() {
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

krun::install::helm::common() {
    echo "Installing Helm package manager..."

    local system_info os arch tag install_dir temp_dir downloaded_file download_url extracted_helm
    system_info=$(krun::install::helm::get_system_info)
    os=$(echo "$system_info" | cut -d' ' -f1)
    arch=$(echo "$system_info" | cut -d' ' -f2)
    tag="$helm_version"
    [[ "$helm_version" == "latest" ]] && tag=$(krun::install::helm::get_latest_version)
    tag=${tag#v}
    install_dir=$(krun::install::helm::install_dir)

    echo "Downloading Helm ${tag} for ${os}/${arch}..."
    temp_dir=$(mktemp -d)
    downloaded_file="${temp_dir}/helm.tar.gz"
    download_url="https://get.helm.sh/helm-v${tag}-${os}-${arch}.tar.gz"

    if ! krun::install::helm::download_file "$download_url" "$downloaded_file"; then
        echo "Primary download failed, trying GitHub release URL..." >&2
        download_url="https://github.com/helm/helm/releases/download/v${tag}/helm-v${tag}-${os}-${arch}.tar.gz"
        if ! krun::install::helm::download_file "$download_url" "$downloaded_file"; then
            echo "✗ Failed to download Helm"
            rm -rf "$temp_dir"
            return 1
        fi
    fi

    if ! gzip -t "$downloaded_file" 2>/dev/null; then
        echo "✗ Downloaded file is not a valid tarball"
        rm -rf "$temp_dir"
        return 1
    fi

    tar -xzf "$downloaded_file" -C "$temp_dir"
    extracted_helm="${temp_dir}/${os}-${arch}/helm"
    if [[ ! -f "$extracted_helm" ]]; then
        extracted_helm=$(find "$temp_dir" -type f -name helm | head -n1)
    fi

    if [[ ! -f "$extracted_helm" ]]; then
        echo "✗ Helm binary not found in archive"
        rm -rf "$temp_dir"
        return 1
    fi

    install -m 755 "$extracted_helm" "${install_dir}/helm"
    rm -rf "$temp_dir"

    if [[ ! -x "${install_dir}/helm" ]]; then
        echo "✗ Helm binary not installed at ${install_dir}/helm"
        return 1
    fi

    if ! "${install_dir}/helm" version --short >/dev/null 2>&1; then
        echo "✗ Helm binary installed but failed to run"
        return 1
    fi

    echo "✓ Helm installed successfully at ${install_dir}/helm"
    krun::install::helm::install_plugins "${install_dir}/helm"
    krun::install::helm::verify_installation "${install_dir}/helm"
}

krun::install::helm::install_plugins() {
    local helm_bin="${1:-helm}"
    echo "Installing common Helm plugins..."

    local plugins=(
        "https://github.com/databus23/helm-diff"
        "https://github.com/jkroepke/helm-secrets"
        "https://github.com/aslafy-z/helm-git"
    )

    for plugin in "${plugins[@]}"; do
        if ! "$helm_bin" plugin install "$plugin" 2>/dev/null; then
            echo "⚠ Plugin installation failed: $plugin"
        fi
    done
}

krun::install::helm::verify_installation() {
    local helm_bin="${1:-helm}"
    echo "Verifying Helm installation..."

    if [[ ! -x "$helm_bin" ]] && command -v "$helm_bin" >/dev/null 2>&1; then
        helm_bin=$(command -v "$helm_bin")
    fi

    if [[ -x "$helm_bin" ]]; then
        echo "✓ helm command is available at ${helm_bin}"
        "$helm_bin" version --short
        echo ""
        echo "Common commands:"
        echo "  helm repo add <name> <url>    - Add chart repository"
        echo "  helm install <name> <chart>   - Install chart"
        echo "  helm list                      - List releases"
        echo "  helm plugin list              - List plugins"
        echo ""
        echo "Example: helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx"
        echo "Helm is ready to use!"
        return 0
    fi

    echo "✗ helm command not found"
    return 1
}

# run main
krun::install::helm::run "$@"
