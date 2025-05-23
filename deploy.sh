#!/usr/bin/env bash

# Copyright (c) 2024 Kk
# MIT License: https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# Config
deploy_path="${deploy_path:-"$HOME/.krun"}"
bin_path="${deploy_path}/bin"
config_path="${deploy_path}/config"
binary_base_url="https://raw.githubusercontent.com/kevin197011/krun/main/bin"
default_shell_rc="$HOME/.bashrc"

# Functions

deploy::platform() {
    local os arch
    case "$(uname -s)" in
    Linux*) os="linux" ;;
    Darwin*) os="darwin" ;;
    *)
        echo "❌ Unsupported OS: $(uname -s)" >&2
        exit 1
        ;;
    esac

    case "$(uname -m)" in
    x86_64) arch="amd64" ;;
    arm64 | aarch64) arch="arm64" ;;
    *)
        echo "❌ Unsupported architecture: $(uname -m)" >&2
        exit 1
        ;;
    esac

    echo "${os}-${arch}"
}

deploy::install() {
    mkdir -p "$bin_path" "$config_path"

    local platform binary_url
    binary_url="${binary_base_url}/krun"

    if ! command -v python >/dev/null 2>&1; then
        platform="$(deploy::platform)"
        binary_url="${binary_base_url}/krun-${platform}"
    fi

    echo "🔽 Downloading krun from ${binary_url}..."
    curl -fsSL -o "${bin_path}/krun" "$binary_url"
    chmod +x "${bin_path}/krun"
    echo "✅ Installed krun to ${bin_path}/krun"
}

deploy::detect_shell_rc() {
    if [[ "${SHELL:-}" == */zsh ]] || command -v brew >/dev/null; then
        echo "$HOME/.zshrc"
    else
        echo "$default_shell_rc"
    fi
}

deploy::config() {
    local shell_rc
    shell_rc="$(deploy::detect_shell_rc)"

    if ! grep -qs "${bin_path}" "$shell_rc"; then
        echo "export PATH=\"\$PATH:${bin_path}\"" >>"$shell_rc"
        echo "🛠️  Added ${bin_path} to PATH in ${shell_rc}"
    else
        echo "ℹ️  ${bin_path} is already in PATH"
    fi
}

deploy::status() {
    echo "🚀 Running krun status..."
    if ! "${bin_path}/krun" status; then
        echo "⚠️ krun status failed"
    fi
}

deploy::uninstall() {
    echo "🧹 Uninstalling krun..."
    rm -rf "${deploy_path}"
    echo "✅ Removed ${deploy_path}"
}

deploy::main() {
    deploy::install
    deploy::config
    deploy::status
}

# ====== Entry Point ======
deploy::main "$@"
