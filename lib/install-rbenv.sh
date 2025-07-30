#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-rbenv.sh | bash

# vars
rbenv_version=${rbenv_version:-latest}

# run code
krun::install::rbenv::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::rbenv::centos() {
    echo "Installing rbenv on CentOS/RHEL..."
    yum install -y git curl
    yum groupinstall -y "Development Tools" || yum install -y gcc make
    yum install -y openssl-devel zlib-devel readline-devel sqlite-devel bzip2-devel libffi-devel libyaml-devel ncurses-devel
    krun::install::rbenv::common
}

# debian code
krun::install::rbenv::debian() {
    echo "Installing rbenv on Debian/Ubuntu..."
    apt-get update
    apt-get install -y git curl build-essential libssl-dev zlib1g-dev libreadline-dev libsqlite3-dev libbz2-dev libffi-dev libyaml-dev libncurses5-dev autoconf bison libtool
    krun::install::rbenv::common
}

# mac code
krun::install::rbenv::mac() {
    echo "Installing rbenv on macOS..."
    if command -v brew >/dev/null 2>&1; then
        brew install rbenv ruby-build
        echo "✓ rbenv installed via Homebrew"
        krun::install::rbenv::configure_shell
        krun::install::rbenv::verify_installation
        return
    fi
    echo "Homebrew not found, installing manually..."
    krun::install::rbenv::common
}

# get latest version
krun::install::rbenv::get_latest_version() {
    curl -fsSL https://api.github.com/repos/rbenv/rbenv/releases/latest | grep tag_name | head -n1 | cut -d '"' -f 4
}

# common code
krun::install::rbenv::common() {
    echo "Installing rbenv version manager..."
    local rbenv_dir="$HOME/.rbenv"
    local tag="$rbenv_version"

    [[ -d "$rbenv_dir" ]] && mv "$rbenv_dir" "${rbenv_dir}.backup.$(date +%Y%m%d-%H%M%S)"

    if [[ "$rbenv_version" == "latest" ]]; then
        tag=$(krun::install::rbenv::get_latest_version)
        [[ -z "$tag" ]] && tag="master"
    fi

    echo "Cloning rbenv ($tag)..."
    git clone https://github.com/rbenv/rbenv.git "$rbenv_dir" --branch "$tag"
    [[ ! -d "$rbenv_dir" ]] && {
        echo "✗ rbenv installation failed"
        return 1
    }
    echo "✓ rbenv installed"

    echo "Installing ruby-build plugin..."
    git clone https://github.com/rbenv/ruby-build.git "$rbenv_dir/plugins/ruby-build" || {
        echo "⚠ ruby-build plugin installation failed, continuing..."
    }

    krun::install::rbenv::configure_shell
    source "$rbenv_dir/bin/rbenv"
    krun::install::rbenv::verify_installation
}

# Configure shell integration
krun::install::rbenv::configure_shell() {
    echo "Configuring shell integration..."
    local rbenv_dir="$HOME/.rbenv"
    local profiles=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc" "$HOME/.profile")

    for profile in "${profiles[@]}"; do
        [[ -f "$profile" ]] && ! grep -q "rbenv init" "$profile" 2>/dev/null && {
            echo "" >>"$profile"
            echo "# rbenv version manager" >>"$profile"
            echo 'eval "$(rbenv init -)"' >>"$profile"
            echo "✓ Configured rbenv in $profile"
        }
    done

    local fish_config_dir="$HOME/.config/fish"
    [[ -d "$fish_config_dir" ]] && {
        mkdir -p "$fish_config_dir/conf.d"
        echo 'status --is-interactive; and rbenv init - fish | source' >"$fish_config_dir/conf.d/rbenv.fish"
        echo "✓ Configured rbenv for fish shell"
    }
}

# Verify rbenv installation
krun::install::rbenv::verify_installation() {
    echo "Verifying rbenv installation..."
    local rbenv_dir="$HOME/.rbenv"

    ! command -v rbenv >/dev/null 2>&1 && [[ -f "$rbenv_dir/bin/rbenv" ]] && source "$rbenv_dir/bin/rbenv"

    if command -v rbenv >/dev/null 2>&1; then
        echo "✓ rbenv command is available"
        rbenv version
        rbenv commands 2>/dev/null && echo "✓ rbenv commands working"
        echo ""
        echo "=== rbenv Installation Summary ==="
        echo "Installation directory: $rbenv_dir"
        echo "Version: $(rbenv version 2>/dev/null || echo 'unknown')"
        echo ""
        echo "Shell configuration updated. Please restart your shell or run:"
        echo "  eval \"\$(rbenv init -)\""
        echo ""
        echo "Common rbenv commands:"
        echo "  rbenv install --list        - List available Ruby versions"
        echo "  rbenv install <version>     - Install a Ruby version"
        echo "  rbenv global <version>      - Set global Ruby version"
        echo "  rbenv local <version>       - Set local Ruby version"
        echo "  rbenv versions              - List installed versions"
        echo "  rbenv version               - Show current version"
        echo ""
        echo "Example: Install Ruby 3.2.0"
        echo "  rbenv install 3.2.0"
        echo "  rbenv global 3.2.0"
        echo "  rbenv rehash"
        echo ""
        echo "rbenv is ready to use!"
    else
        echo "✗ rbenv command not found"
        echo "Please restart your shell or run: eval \"\$(rbenv init -)\""
        return 1
    fi
}

# run main
krun::install::rbenv::run "$@"
