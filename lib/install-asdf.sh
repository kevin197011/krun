#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-asdf.sh | bash

# vars
asdf_version=${asdf_version:-latest}

# run code
krun::install::asdf::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::asdf::centos() {
    echo "Installing asdf on CentOS/RHEL..."

    # Install prerequisites
    yum install -y git curl

    # Install development tools for compiling languages
    yum groupinstall -y "Development Tools" || yum install -y gcc make
    yum install -y \
        openssl-devel \
        zlib-devel \
        readline-devel \
        sqlite-devel \
        bzip2-devel \
        libffi-devel \
        libyaml-devel \
        ncurses-devel

    krun::install::asdf::common
}

# debian code
krun::install::asdf::debian() {
    echo "Installing asdf on Debian/Ubuntu..."

    # Update package lists
    apt-get update

    # Install prerequisites
    apt-get install -y git curl

    # Install development tools for compiling languages
    apt-get install -y \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libreadline-dev \
        libsqlite3-dev \
        libbz2-dev \
        libffi-dev \
        libyaml-dev \
        libncurses5-dev \
        autoconf \
        bison \
        libtool

    krun::install::asdf::common
}

# mac code
krun::install::asdf::mac() {
    echo "Installing asdf on macOS..."

    # Install via Homebrew if available
    if command -v brew >/dev/null 2>&1; then
        brew install asdf
        echo "✓ asdf installed via Homebrew"
        krun::install::asdf::configure_shell
        krun::install::asdf::verify_installation
        return
    else
        echo "Homebrew not found, installing manually..."
        krun::install::asdf::common
    fi
}

# common code
krun::install::asdf::common() {
    echo "Installing asdf version manager..."

    local asdf_dir="$HOME/.asdf"

    # Remove existing installation if exists
    if [[ -d "$asdf_dir" ]]; then
        echo "Existing asdf installation found. Backing up..."
        mv "$asdf_dir" "${asdf_dir}.backup.$(date +%Y%m%d-%H%M%S)"
    fi

    # Clone asdf repository
    echo "Cloning asdf repository..."
    if [[ "$asdf_version" == "latest" ]]; then
        git clone https://github.com/asdf-vm/asdf.git "$asdf_dir" --branch v0.14.0
    else
        git clone https://github.com/asdf-vm/asdf.git "$asdf_dir" --branch "$asdf_version"
    fi

    # Verify installation
    if [[ ! -d "$asdf_dir" ]]; then
        echo "✗ asdf installation failed"
        return 1
    fi

    echo "✓ asdf installed successfully"

    # Configure shell integration
    krun::install::asdf::configure_shell

    # Source asdf for current session
    source "$asdf_dir/asdf.sh"

    # Verify installation
    krun::install::asdf::verify_installation
}

# Configure shell integration
krun::install::asdf::configure_shell() {
    echo "Configuring shell integration..."

    local asdf_dir="$HOME/.asdf"
    local shell_profiles=(
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.zshrc"
        "$HOME/.profile"
    )

    # Check which shell profiles exist and configure them
    for profile in "${shell_profiles[@]}"; do
        if [[ -f "$profile" ]]; then
            # Check if asdf is already configured
            if ! grep -q "asdf.sh" "$profile" 2>/dev/null; then
                echo "" >>"$profile"
                echo "# asdf version manager" >>"$profile"
                echo ". $asdf_dir/asdf.sh" >>"$profile"
                echo ". $asdf_dir/completions/asdf.bash" >>"$profile"
                echo "✓ Configured asdf in $profile"
            else
                echo "✓ asdf already configured in $profile"
            fi
        fi
    done

    # Configure for fish shell if exists
    local fish_config_dir="$HOME/.config/fish"
    if [[ -d "$fish_config_dir" ]]; then
        mkdir -p "$fish_config_dir/conf.d"
        echo "source $asdf_dir/asdf.fish" >"$fish_config_dir/conf.d/asdf.fish"
        echo "✓ Configured asdf for fish shell"
    fi
}

# Verify asdf installation
krun::install::asdf::verify_installation() {
    echo "Verifying asdf installation..."

    local asdf_dir="$HOME/.asdf"

    # Source asdf if not already loaded
    if ! command -v asdf >/dev/null 2>&1; then
        if [[ -f "$asdf_dir/asdf.sh" ]]; then
            source "$asdf_dir/asdf.sh"
        fi
    fi

    # Check asdf command
    if command -v asdf >/dev/null 2>&1; then
        echo "✓ asdf command is available"
        asdf version
    else
        echo "✗ asdf command not found"
        echo "Please restart your shell or run: source $asdf_dir/asdf.sh"
        return 1
    fi

    # Test plugin functionality
    echo "Testing plugin functionality..."
    asdf plugin list 2>/dev/null && echo "✓ Plugin system working"

    echo ""
    echo "=== asdf Installation Summary ==="
    echo "Installation directory: $asdf_dir"
    echo "Version: $(asdf version 2>/dev/null || echo 'unknown')"
    echo ""
    echo "Shell configuration updated. Please restart your shell or run:"
    echo "  source $asdf_dir/asdf.sh"
    echo ""
    echo "Common asdf commands:"
    echo "  asdf plugin list all         - List available plugins"
    echo "  asdf plugin add <name>       - Add a plugin"
    echo "  asdf list all <name>         - List available versions"
    echo "  asdf install <name> <version> - Install a version"
    echo "  asdf global <name> <version>  - Set global version"
    echo "  asdf local <name> <version>   - Set local version"
    echo ""
    echo "Example: Install Node.js"
    echo "  asdf plugin add nodejs"
    echo "  asdf install nodejs latest"
    echo "  asdf global nodejs latest"
    echo ""
    echo "asdf is ready to use!"
}

# run main
krun::install::asdf::run "$@"
