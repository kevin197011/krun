#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_helm.sh | bash

# vars
helm_version=${helm_version:-latest}
helm_install_plugins=${helm_install_plugins:-true}
helm_use_official_script=${helm_use_official_script:-true}
# Pin plugin versions to avoid GitHub API lookups on restricted networks.
helm_diff_version=${helm_diff_version:-v3.15.8}
helm_secrets_version=${helm_secrets_version:-v4.7.6}
helm_git_version=${helm_git_version:-1.5.2}
# Helm 4 verifies plugin signatures by default; disable for unattended installs.
helm_plugin_verify=${helm_plugin_verify:-false}
helm_use_proxy=${helm_use_proxy:-false}
helm_proxy_host=${helm_proxy_host:-10.170.1.19}
helm_proxy_port=${helm_proxy_port:-8888}
install_helm_script_rev=${install_helm_script_rev:-20250608-plugins-v3}

krun::install::helm::configure_proxy() {
    [[ "$helm_use_proxy" != "true" ]] && return 0

    local proxy_url="http://${helm_proxy_host}:${helm_proxy_port}"
    export http_proxy="$proxy_url"
    export https_proxy="$proxy_url"
    export HTTP_PROXY="$proxy_url"
    export HTTPS_PROXY="$proxy_url"
    echo "✓ Proxy enabled for Helm installer: ${proxy_url}"
}

# run code
krun::install::helm::run() {
    krun::install::helm::configure_proxy
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
        dnf install -y curl tar git
    else
        yum install -y curl tar git
    fi
    krun::install::helm::common
}

# debian code
krun::install::helm::debian() {
    echo "Installing Helm on Debian/Ubuntu..."
    [[ "$(id -u)" -ne 0 ]] && echo "✗ Please run as root" && return 1

    apt-get update
    apt-get install -y curl tar git
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

krun::install::helm::get_github_latest_tag() {
    local repo="$1"
    local fallback="$2"
    local version

    version=$(curl -fsSL --connect-timeout 5 --max-time 10 "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null | grep tag_name | head -n1 | cut -d '"' -f 4)
    if [[ -z "$version" ]]; then
        version=$(curl -fsSL --connect-timeout 5 --max-time 10 "https://ghproxy.link/https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null | grep tag_name | head -n1 | cut -d '"' -f 4)
    fi
    echo "${version:-$fallback}"
}

krun::install::helm::helm_major_version() {
    local helm_bin="$1"
    "$helm_bin" version --short 2>/dev/null | sed -E 's/^v?([0-9]+).*/\1/'
}

krun::install::helm::plugin_installed() {
    local helm_bin="$1"
    local plugin_name="$2"
    "$helm_bin" plugin list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "$plugin_name"
}

krun::install::helm::plugin_verify_args() {
    if [[ "$helm_plugin_verify" == "true" ]]; then
        return 0
    fi
    echo --verify=false
}

krun::install::helm::download_file() {
    local url="$1"
    local dest="$2"
    local mirror mirrors=()

    mirrors=(
        "$url"
        "https://ghproxy.link/${url}"
        "https://mirror.ghproxy.com/${url}"
    )

    for mirror in "${mirrors[@]}"; do
        echo "  downloading: ${mirror}" >&2
        if curl -fsSL --connect-timeout 15 --max-time 300 "$mirror" -o "$dest"; then
            [[ -s "$dest" ]] && return 0
        fi
        rm -f "$dest"
    done

    echo "✗ Download failed: ${url}" >&2
    return 1
}

krun::install::helm::helm_plugins_dir() {
    local helm_bin="$1"
    local plugins_dir

    plugins_dir=$("$helm_bin" env HELM_PLUGINS 2>/dev/null | sed -n 's/^HELM_PLUGINS=\(.*\)$/\1/p' | tr -d '"')
    if [[ -z "$plugins_dir" ]]; then
        plugins_dir="${HOME}/.local/share/helm/plugins"
    fi
    mkdir -p "$plugins_dir"
    echo "$plugins_dir"
}

krun::install::helm::install_plugin_tgz() {
    local helm_bin="$1"
    local url="$2"
    local label="${3:-plugin}"
    local tmpfile output verify_flag
    local verify_args=()

    tmpfile=$(mktemp /tmp/helm-plugin.XXXXXX.tgz)

    if ! krun::install::helm::download_file "$url" "$tmpfile"; then
        rm -f "$tmpfile"
        return 1
    fi

    verify_flag=$(krun::install::helm::plugin_verify_args || true)
    if [[ -n "$verify_flag" ]]; then
        verify_args=("$verify_flag")
    fi

    if output=$("$helm_bin" plugin install "${verify_args[@]}" "$tmpfile" 2>&1); then
        rm -f "$tmpfile"
        echo "✓ Plugin installed: ${label}"
        return 0
    fi

    rm -f "$tmpfile"
    echo "⚠ Plugin installation failed: ${label}" >&2
    [[ -n "$output" ]] && echo "$output" >&2
    return 1
}

krun::install::helm::install_helm_plugin() {
    local helm_bin="$1"
    local plugin_url="$2"
    local label="${3:-$plugin_url}"

    if [[ "$plugin_url" == *.tgz || "$plugin_url" == *.tar.gz ]]; then
        krun::install::helm::install_plugin_tgz "$helm_bin" "$plugin_url" "$label"
        return $?
    fi

    local output verify_flag verify_args=()
    verify_flag=$(krun::install::helm::plugin_verify_args || true)
    if [[ -n "$verify_flag" ]]; then
        verify_args=("$verify_flag")
    fi

    if output=$("$helm_bin" plugin install "${verify_args[@]}" "$plugin_url" 2>&1); then
        echo "✓ Plugin installed: ${label}"
        return 0
    fi

    echo "Direct plugin install failed, trying ghproxy repo URL..." >&2
    if output=$("$helm_bin" plugin install "${verify_args[@]}" "https://ghproxy.link/${plugin_url}" 2>&1); then
        echo "✓ Plugin installed via proxy: ${label}"
        return 0
    fi

    echo "⚠ Plugin installation failed: ${label}" >&2
    [[ -n "$output" ]] && echo "$output" >&2
    return 1
}

krun::install::helm::map_helm_diff_platform() {
    local raw_os raw_arch platform_os platform_arch
    raw_os=$(uname -s)
    raw_arch=$(uname -m)

    case "$raw_os" in
        Darwin) platform_os="macos" ;;
        Linux) platform_os="linux" ;;
        FreeBSD) platform_os="freebsd" ;;
        MINGW* | MSYS* | CYGWIN*) platform_os="windows" ;;
        *) platform_os="linux" ;;
    esac

    case "$raw_arch" in
        x86_64) platform_arch="amd64" ;;
        aarch64 | arm64) platform_arch="arm64" ;;
        armv7l) platform_arch="armv7" ;;
        armv6l) platform_arch="armv6" ;;
        ppc64le) platform_arch="ppc64le" ;;
        s390x) platform_arch="s390x" ;;
        *) platform_arch="amd64" ;;
    esac

    echo "${platform_os}-${platform_arch}"
}

krun::install::helm::install_helm_diff() {
    local helm_bin="$1"
    local tag platform plugin_url output
    local verify_flag verify_args=()

    if krun::install::helm::plugin_installed "$helm_bin" diff; then
        echo "✓ Plugin diff already installed"
        return 0
    fi

    tag="$helm_diff_version"
    [[ "$tag" == "latest" ]] && tag=$(krun::install::helm::get_github_latest_tag "databus23/helm-diff" "v3.15.8")
    platform=$(krun::install::helm::map_helm_diff_platform)
    plugin_url="https://github.com/databus23/helm-diff/releases/download/${tag}/helm-diff-${platform}.tgz"

    echo "Installing helm-diff ${tag} (${platform})..."
    if krun::install::helm::install_plugin_tgz "$helm_bin" "$plugin_url" "helm-diff ${tag}"; then
        return 0
    fi

    verify_flag=$(krun::install::helm::plugin_verify_args || true)
    if [[ -n "$verify_flag" ]]; then
        verify_args=("$verify_flag")
    fi

    echo "Trying helm-diff repo install for ${tag}..." >&2
    if output=$("$helm_bin" plugin install "${verify_args[@]}" "https://github.com/databus23/helm-diff" --version "$tag" 2>&1); then
        echo "✓ Plugin installed: helm-diff ${tag}"
        return 0
    fi
    if output=$("$helm_bin" plugin install "${verify_args[@]}" "https://ghproxy.link/https://github.com/databus23/helm-diff" --version "$tag" 2>&1); then
        echo "✓ Plugin installed via proxy: helm-diff ${tag}"
        return 0
    fi

    echo "⚠ Plugin installation failed: helm-diff ${tag}" >&2
    [[ -n "$output" ]] && echo "$output" >&2
    return 1
}

krun::install::helm::install_helm_secrets() {
    local helm_bin="$1"
    local major tag version_plain plugin_url plugin_base package

    major=$(krun::install::helm::helm_major_version "$helm_bin")
    tag="$helm_secrets_version"
    [[ "$tag" == "latest" ]] && tag=$(krun::install::helm::get_github_latest_tag "jkroepke/helm-secrets" "v4.7.6")
    version_plain=${tag#v}
    plugin_base="https://github.com/jkroepke/helm-secrets/releases/download/${tag}"

    if [[ "$major" -ge 4 ]]; then
        local packages=(
            "secrets-${version_plain}.tgz"
            "secrets-getter-${version_plain}.tgz"
            "secrets-post-renderer-${version_plain}.tgz"
        )

        echo "Installing helm-secrets ${tag} (Helm 4 split packages)..."
        for package in "${packages[@]}"; do
            plugin_url="${plugin_base}/${package}"
            krun::install::helm::install_plugin_tgz "$helm_bin" "$plugin_url" "$package" || true
        done

        if krun::install::helm::plugin_installed "$helm_bin" secrets; then
            echo "✓ helm-secrets core plugin installed"
            return 0
        fi

        echo "⚠ helm-secrets installation incomplete for Helm 4" >&2
        return 1
    fi

    if krun::install::helm::plugin_installed "$helm_bin" secrets; then
        echo "✓ Plugin secrets already installed"
        return 0
    fi

    plugin_url="${plugin_base}/helm-secrets.tar.gz"
    echo "Installing helm-secrets ${tag} (Helm 3 tarball)..."
    krun::install::helm::install_plugin_tgz "$helm_bin" "$plugin_url" "helm-secrets ${tag}"
}

krun::install::helm::install_helm_git_from_archive() {
    local helm_bin="$1"
    local tag="$2"
    local plugins_dir archive_url tmpdir dest archive_tag extracted_dir

    plugins_dir=$(krun::install::helm::helm_plugins_dir "$helm_bin")
    dest="${plugins_dir}/helm-git"
    [[ -d "$dest" ]] && rm -rf "$dest"

    tmpdir=$(mktemp -d /tmp/helm-git.XXXXXX)

    for archive_tag in "$tag" "v${tag}"; do
        archive_url="https://github.com/aslafy-z/helm-git/archive/refs/tags/${archive_tag}.tar.gz"
        echo "Installing helm-git ${tag} from source archive (${archive_tag})..."
        if ! krun::install::helm::download_file "$archive_url" "${tmpdir}/helm-git.tar.gz"; then
            continue
        fi

        tar -xzf "${tmpdir}/helm-git.tar.gz" -C "$tmpdir"
        extracted_dir=$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -n1)
        if [[ -z "$extracted_dir" || ! -f "${extracted_dir}/plugin.yaml" ]]; then
            rm -rf "${tmpdir:?}"/*
            continue
        fi

        mv "$extracted_dir" "$dest"
        rm -rf "$tmpdir"
        echo "✓ Plugin installed from archive: helm-git ${tag}"
        return 0
    done

    rm -rf "$tmpdir"
    return 1
}

krun::install::helm::install_helm_git() {
    local helm_bin="$1"
    local tag="$helm_git_version"
    local output verify_flag verify_args=()

    if krun::install::helm::plugin_installed "$helm_bin" helm-git; then
        echo "✓ Plugin helm-git already installed"
        return 0
    fi

    verify_flag=$(krun::install::helm::plugin_verify_args || true)
    if [[ -n "$verify_flag" ]]; then
        verify_args=("$verify_flag")
    fi

    echo "Installing helm-git ${tag}..."
    if output=$("$helm_bin" plugin install "${verify_args[@]}" "https://github.com/aslafy-z/helm-git" --version "$tag" 2>&1); then
        echo "✓ Plugin installed: helm-git ${tag}"
        return 0
    fi
    if output=$("$helm_bin" plugin install "${verify_args[@]}" "https://ghproxy.link/https://github.com/aslafy-z/helm-git" --version "$tag" 2>&1); then
        echo "✓ Plugin installed via proxy: helm-git ${tag}"
        return 0
    fi

    if krun::install::helm::install_helm_git_from_archive "$helm_bin" "$tag"; then
        return 0
    fi

    echo "⚠ Plugin installation failed: helm-git ${tag}" >&2
    [[ -n "$output" ]] && echo "$output" >&2
    return 1
}

krun::install::helm::install_plugins() {
    local helm_bin="${1:-helm}"
    echo "Installing common Helm plugins (${install_helm_script_rev})..."

    krun::install::helm::install_helm_diff "$helm_bin" || true
    krun::install::helm::install_helm_secrets "$helm_bin" || true
    krun::install::helm::install_helm_git "$helm_bin" || true

    echo ""
    echo "Installed plugins:"
    "$helm_bin" plugin list 2>/dev/null || true
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
