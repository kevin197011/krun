#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-fonts-nerd.sh | bash

# vars
FONT_NAME="JetBrainsMono"
FONT_DIR_MAC="$HOME/Library/Fonts"
FONT_DIR_LINUX="$HOME/.local/share/fonts"

# run code
krun::install::fonts_nerd::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::fonts_nerd::centos() {
    krun::install::fonts_nerd::install_linux
}

# debian code
krun::install::fonts_nerd::debian() {
    krun::install::fonts_nerd::install_linux
}

# mac code
krun::install::fonts_nerd::mac() {
    if ! command -v brew >/dev/null 2>&1; then
        echo "Error: Homebrew is required. Install it from https://brew.sh" >&2
        exit 1
    fi
    
    brew tap homebrew/cask-fonts 2>/dev/null || true
    brew install --cask font-jetbrains-mono-nerd-font
}

# install for linux
krun::install::fonts_nerd::install_linux() {
    local download_cmd download_file
    if command -v curl >/dev/null 2>&1; then
        download_cmd="curl -fsSL -o"
    elif command -v wget >/dev/null 2>&1; then
        download_cmd="wget -qO"
    else
        echo "Error: curl or wget is required" >&2
        exit 1
    fi
    
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    download_file="$temp_dir/JetBrainsMono.tar.xz"
    echo "Downloading ${FONT_NAME} Nerd Font..."
    $download_cmd "$download_file" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
    
    mkdir -p "$FONT_DIR_LINUX"
    
    # Extract tar.xz file (tar with xz compression)
    if tar --version | grep -q "GNU tar"; then
        tar -xJf "$download_file" -C "$temp_dir"
    else
        # Fallback: try with xz command if available
        if command -v xz >/dev/null 2>&1; then
            xz -dc "$download_file" | tar -xf - -C "$temp_dir"
        else
            # Try regular tar (some systems support -J)
            tar -xf "$download_file" -C "$temp_dir" 2>/dev/null || {
                echo "Error: Cannot extract tar.xz file. Please install xz-utils." >&2
                exit 1
            }
        fi
    fi
    
    # Copy font files (may be in a subdirectory)
    local font_found
    font_found=$(find "$temp_dir" \( -name "*.ttf" -o -name "*.otf" \) -print -quit 2>/dev/null)
    if [ -z "$font_found" ]; then
        echo "Error: No font files found in archive" >&2
        exit 1
    fi
    
    find "$temp_dir" \( -name "*.ttf" -o -name "*.otf" \) -exec cp {} "$FONT_DIR_LINUX/" \;
    
    if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -fv "$FONT_DIR_LINUX"
    fi
    
    echo "${FONT_NAME} Nerd Font installed to $FONT_DIR_LINUX"
}

# run main
krun::install::fonts_nerd::run "$@"
