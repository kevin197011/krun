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
helm_install_plugins=${helm_install_plugins:-true}
helm_use_official_script=${helm_use_official_script:-true}

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
        krun::install::helm::verify_installation "$(command -v helm)"
        return
    fi

    if command -v brew >/dev/null 2>&1; then
        brew install helm
        echo "✓ Helm installed via Homebrew"
        krun::install::helm::verify_installation "$(command -v helm)"
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

krun::install::helm::resolve_tag() {
    local tag="$helm_version"
    [[ "$helm_version" == "latest" ]] && tag=$(krun::install::helm::get_latest_version)
    tag=${tag#v}
    echo "$tag"
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

    echo "${HOME}/.local/bin"
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

krun::install::helm::ensure_in_path() {
    local install_dir="$1"
    local helm_bin="${install_dir}/helm"

    [[ -x "$helm_bin" ]] || return 1

    mkdir -p "$(dirname "$helm_bin")"

    if [[ "$install_dir" == "/usr/bin" ]] && [[ ! -e /usr/local/bin/helm ]]; then
        ln -sf "$helm_bin" /usr/local/bin/helm
    elif [[ "$install_dir" == "/usr/local/bin" ]] && [[ ! -e /usr/bin/helm ]]; then
        ln -sf "$helm_bin" /usr/bin/helm
    fi

    export PATH="${install_dir}:/usr/local/bin:/usr/bin:/bin:${PATH}"
    hash -r 2>/dev/null || true
}

krun::install::helm::install_official_script() {
    local install_dir tag installer_url temp_installer
    install_dir=$(krun::install::helm::install_dir)
    tag=$(krun::install::helm::resolve_tag)
    installer_url="https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4"
    temp_installer=$(mktemp)

    echo "Installing Helm ${tag} via official get-helm-4 script..."
    if ! curl -fsSL --connect-timeout 10 --max-time 120 "$installer_url" -o "$temp_installer" 2>/dev/null; then
        curl -fsSL --connect-timeout 10 --max-time 120 "https://ghproxy.link/${installer_url}" -o "$temp_installer"
    fi

    chmod 700 "$temp_installer"
    DESIRED_VERSION="v${tag}" \
        HELM_INSTALL_DIR="$install_dir" \
        USE_SUDO=false \
        VERIFY_SIGNATURES=false \
        VERIFY_CHECKSUM=true \
        bash "$temp_installer"
    rm -f "$temp_installer"

    krun::install::helm::ensure_in_path "$install_dir"
    [[ -x "${install_dir}/helm" ]]
}

krun::install::helm::install_from_tarball() {
    local system_info os arch tag install_dir temp_dir downloaded_file download_url extracted_helm
    system_info=$(krun::install::helm::get_system_info)
    os=$(echo "$system_info" | cut -d' ' -f1)
    arch=$(echo "$system_info" | cut -d' ' -f2)
    tag=$(krun::install::helm::resolve_tag)
    install_dir=$(krun::install::helm::install_dir)

    echo "Installing Helm ${tag} from official binary release (${os}/${arch})..."
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

    mkdir -p "$install_dir"
    install -m 755 "$extracted_helm" "${install_dir}/helm"
    rm -rf "$temp_dir"
    krun::install::helm::ensure_in_path "$install_dir"
    [[ -x "${install_dir}/helm" ]]
}

krun::install::helm::common() {
    echo "Installing Helm package manager..."

    local install_dir helm_bin installed=false
    install_dir=$(krun::install::helm::install_dir)

    if [[ "$helm_use_official_script" == "true" ]]; then
        if krun::install::helm::install_official_script; then
            installed=true
        else
            echo "Official installer failed, falling back to tarball..." >&2
        fi
    fi

    if [[ "$installed" == "false" ]]; then
        krun::install::helm::install_from_tarball || return 1
    fi

    helm_bin="${install_dir}/helm"
    if [[ ! -x "$helm_bin" ]] && command -v helm >/dev/null 2>&1; then
        helm_bin=$(command -v helm)
    fi

    if [[ ! -x "$helm_bin" ]]; then
        echo "✗ Helm binary not found after installation"
        echo "Checked: ${install_dir}/helm, /usr/bin/helm, /usr/local/bin/helm"
        return 1
    fi

    if ! "$helm_bin" version --short >/dev/null 2>&1; then
        echo "✗ Helm binary exists but failed to run: ${helm_bin}"
        return 1
    fi

    echo "✓ Helm installed successfully at ${helm_bin}"
    if [[ "$helm_install_plugins" == "true" ]]; then
        krun::install::helm::install_plugins "$helm_bin"
    fi
    krun::install::helm::verify_installation "$helm_bin"
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

    krun::install::helm::ensure_in_path "$(dirname "$helm_bin")"

    if [[ ! -x "$helm_bin" ]] && command -v helm >/dev/null 2>&1; then
        helm_bin=$(command -v helm)
    fi

    if [[ -x "$helm_bin" ]]; then
        echo "✓ helm command is available at ${helm_bin}"
        "$helm_bin" version --short
        if command -v helm >/dev/null 2>&1; then
            echo "✓ helm is available in PATH as: $(command -v helm)"
        else
            echo "⚠ helm is installed but not in current PATH; use: ${helm_bin}"
            echo "  or run: export PATH=\"$(dirname "$helm_bin"):\$PATH\""
        fi
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
