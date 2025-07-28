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
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::asdf::centos() {
    echo "Installing asdf on CentOS/RHEL..."
    yum install -y git curl epel-release
    yum config-manager --set-enabled crb
    yum makecache
    yum groupinstall -y "Development Tools" || yum install -y gcc make
    yum install -y openssl-devel zlib-devel readline-devel sqlite-devel bzip2-devel libffi-devel libyaml-devel ncurses-devel
    krun::install::asdf::common
}

# debian code
krun::install::asdf::debian() {
    echo "Installing asdf on Debian/Ubuntu..."
    apt-get update
    apt-get install -y git curl build-essential libssl-dev zlib1g-dev libreadline-dev libsqlite3-dev libbz2-dev libffi-dev libyaml-dev libncurses5-dev autoconf bison libtool
    krun::install::asdf::common
}

# mac code
krun::install::asdf::mac() {
    echo "Installing asdf on macOS..."
    if command -v brew >/dev/null 2>&1; then
        brew install asdf
        echo "✓ asdf installed via Homebrew"
        krun::install::asdf::configure_shell
        krun::install::asdf::verify_installation
        return
    fi
    echo "Homebrew not found, installing manually..."
    krun::install::asdf::common
}

# get latest version
krun::install::asdf::get_latest_version() {
    curl -fsSL https://api.github.com/repos/asdf-vm/asdf/releases/latest | grep tag_name | head -n1 | cut -d '"' -f 4
}

# common code
krun::install::asdf::common() {
    echo "Installing asdf version manager..."
    local asdf_dir="$HOME/.asdf"
    local tag="$asdf_version"

    [[ -d "$asdf_dir" ]] && mv "$asdf_dir" "${asdf_dir}.backup.$(date +%Y%m%d-%H%M%S)"

    if [[ "$asdf_version" == "latest" ]]; then
        tag=$(krun::install::asdf::get_latest_version)
        [[ -z "$tag" ]] && tag="master"
    fi

    echo "Cloning asdf ($tag)..."
    git clone https://github.com/asdf-vm/asdf.git "$asdf_dir" --branch "$tag"
    [[ ! -d "$asdf_dir" ]] && {
        echo "✗ asdf installation failed"
        return 1
    }
    echo "✓ asdf installed"

    krun::install::asdf::configure_shell
    source "$asdf_dir/asdf.sh"
    krun::install::asdf::verify_installation
}

# Configure shell integration
krun::install::asdf::configure_shell() {
    echo "Configuring shell integration..."
    local asdf_dir="$HOME/.asdf"
    local profiles=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc" "$HOME/.profile")

    for profile in "${profiles[@]}"; do
        [[ -f "$profile" ]] && ! grep -q "asdf.sh" "$profile" 2>/dev/null && {
            echo "" >>"$profile"
            echo "# asdf version manager" >>"$profile"
            echo ". $asdf_dir/asdf.sh" >>"$profile"
            echo ". $asdf_dir/completions/asdf.bash" >>"$profile"
            echo "✓ Configured asdf in $profile"
        }
    done

    local fish_config_dir="$HOME/.config/fish"
    [[ -d "$fish_config_dir" ]] && {
        mkdir -p "$fish_config_dir/conf.d"
        echo "source $asdf_dir/asdf.fish" >"$fish_config_dir/conf.d/asdf.fish"
        echo "✓ Configured asdf for fish shell"
    }
}

# Verify asdf installation
krun::install::asdf::verify_installation() {
    echo "Verifying asdf installation..."
    local asdf_dir="$HOME/.asdf"

    ! command -v asdf >/dev/null 2>&1 && [[ -f "$asdf_dir/asdf.sh" ]] && source "$asdf_dir/asdf.sh"

    if command -v asdf >/dev/null 2>&1; then
        echo "✓ asdf command is available"
        asdf version
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
    else
        echo "✗ asdf command not found"
        echo "Please restart your shell or run: source $asdf_dir/asdf.sh"
        return 1
    fi
}

# run main
krun::install::asdf::run "$@"
