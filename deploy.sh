#!/usr/bin/env bash

# Copyright (c) 2024 Kk
# MIT License: https://opensource.org/licenses/MIT

set -e

export deploy_path=${deploy_path:-"$HOME/.krun"}
export bin_path="${deploy_path}/bin"

detect_platform() {
    unameOut="$(uname -s)"
    case "${unameOut}" in
    Linux*) os=linux ;;
    Darwin*) os=darwin ;;
    CYGWIN* | MINGW* | MSYS*) os=windows ;;
    *)
        echo "Unsupported OS: ${unameOut}"
        exit 1
        ;;
    esac

    arch=$(uname -m)
    case "${arch}" in
    x86_64) arch=amd64 ;;
    arm64 | aarch64) arch=arm64 ;;
    *)
        echo "Unsupported architecture: ${arch}"
        exit 1
        ;;
    esac

    extension=""
    [ "$os" = "windows" ] && extension=".exe"

    platform="${os}-${arch}"
    echo "$platform$extension"
}

deploy::install() {
    mkdir -pv "${bin_path}"
    mkdir -pv "${deploy_path}/config"

    binary_name=$(detect_platform)

    url_base="https://raw.githubusercontent.com/kevin197011/krun/main/bin"
    echo "Downloading krun for platform: $binary_name"

    curl -fsSL -o "${bin_path}/krun${binary_name##*.exe}" "$url_base/krun-${binary_name}"
    chmod +x "${bin_path}/krun"
}

deploy::config() {
    # macOS shell config
    if command -v brew >/dev/null; then
        grep -q "${bin_path}" ~/.zshrc || echo "export PATH=\$PATH:${bin_path}" >>~/.zshrc
    fi

    # Ubuntu shell config
    if [[ -f /etc/lsb-release ]] && grep -qi "ubuntu" /etc/lsb-release; then
        grep -q "${bin_path}" ~/.bashrc || echo "export PATH=\$PATH:${bin_path}" >>~/.bashrc
    fi
}

deploy::status() {
    echo "Running krun status..."
    "${bin_path}/krun" status || echo "krun status failed"
}

deploy::uninstall() {
    echo "Uninstalling krun..."
    rm -rf "${deploy_path}"
}

deploy::main() {
    deploy::install
    deploy::config
    deploy::status
}

# Run main
deploy::main "$@"
