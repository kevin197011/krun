#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-crane.sh | bash

# vars
CRANE_VERSION="${CRANE_VERSION:-latest}"
CRANE_BIN_DIR="${CRANE_BIN_DIR:-/usr/local/bin}"

krun::install::crane::sudo() {
    [[ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]] && return 0
    command -v sudo >/dev/null 2>&1 && echo "sudo"
}

# run code
krun::install::crane::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::crane::centos() {
    krun::install::crane::common
}

# debian code
krun::install::crane::debian() {
    krun::install::crane::common
}

# mac code
krun::install::crane::mac() {
    if command -v brew >/dev/null 2>&1; then
        brew install crane
        echo "✓ crane installed via Homebrew"
        return
    fi
    krun::install::crane::common
}

krun::install::crane::get_latest_version() {
    curl -fsSL https://api.github.com/repos/google/go-containerregistry/releases/latest 2>/dev/null | grep '"tag_name"' | head -1 | sed -E 's/.*"v([^"]+)".*/\1/' || echo "0.19.0"
}

krun::install::crane::get_system_info() {
    local arch os
    arch=$(uname -m)
    os=$(uname -s)
    [[ "$arch" == "x86_64" ]] && arch="x86_64"
    [[ "$arch" == "aarch64" || "$arch" == "arm64" ]] && arch="arm64"
    [[ "$arch" != "x86_64" && "$arch" != "arm64" ]] && arch="x86_64"
    # release 使用 Darwin / Linux（首字母大写）
    [[ "$os" != "Darwin" ]] && os="Linux"
    echo "$os $arch"
}

# common code
krun::install::crane::common() {
    command -v crane >/dev/null 2>&1 && echo "crane already installed" && crane version && return

    command -v curl >/dev/null 2>&1 || { echo "curl required"; exit 1; }

    local tag="$CRANE_VERSION"
    [[ "$tag" == "latest" ]] && tag=$(krun::install::crane::get_latest_version)
    tag="${tag#v}"

    local system_info
    system_info=$(krun::install::crane::get_system_info)
    local os arch
    os=$(echo "$system_info" | cut -d' ' -f1)
    arch=$(echo "$system_info" | cut -d' ' -f2)

    local url="https://github.com/google/go-containerregistry/releases/download/v${tag}/go-containerregistry_${os}_${arch}.tar.gz"
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf '$tmp_dir'" EXIT

    echo "Downloading crane v${tag} (${os}/${arch})..."
    curl -fsSL "$url" -o "${tmp_dir}/crane.tar.gz" || { echo "Download failed"; exit 1; }

    tar -xzf "${tmp_dir}/crane.tar.gz" -C "$tmp_dir"
    local sudo
    sudo="$(krun::install::crane::sudo)"
    local crane_bin
    crane_bin=$(find "$tmp_dir" -maxdepth 2 -name crane -type f 2>/dev/null | head -1)
    [[ -z "$crane_bin" ]] && crane_bin="${tmp_dir}/crane"
    $sudo mkdir -p "$CRANE_BIN_DIR"
    $sudo mv "$crane_bin" "$CRANE_BIN_DIR/crane"
    $sudo chmod +x "$CRANE_BIN_DIR/crane"
    command -v crane >/dev/null 2>&1 || export PATH="$CRANE_BIN_DIR:$PATH"
    echo "✓ crane installed to $CRANE_BIN_DIR"
    crane version
}

# run main
krun::install::crane::run "$@"
