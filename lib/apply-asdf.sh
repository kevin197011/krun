#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/apply-asdf.sh | bash

# vars

# run code
krun::apply::asdf::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::apply::asdf::centos() {
    echo "Applying asdf configuration on CentOS/RHEL..."
    krun::apply::asdf::common
}

# debian code
krun::apply::asdf::debian() {
    echo "Applying asdf configuration on Debian/Ubuntu..."
    krun::apply::asdf::common
}

# mac code
krun::apply::asdf::mac() {
    echo "Applying asdf configuration on macOS..."
    krun::apply::asdf::common
}

# common code
krun::apply::asdf::common() {
    echo "Applying asdf version manager configuration..."

    # Check if asdf is installed
    if ! command -v asdf >/dev/null 2>&1; then
        echo "asdf is not installed. Installing asdf first..."
        curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-asdf.sh | bash

        # Source asdf
        if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
            source "$HOME/.asdf/asdf.sh"
        fi
    fi

    echo "✓ asdf is available: $(asdf version 2>/dev/null || echo 'unknown')"

    # Install common plugins and tools
    krun::apply::asdf::install_common_tools

    echo ""
    echo "=== asdf Configuration Applied ==="
    echo "Installed plugins:"
    asdf plugin list 2>/dev/null || echo "No plugins installed"
    echo ""
    echo "Installed versions:"
    asdf list 2>/dev/null || echo "No versions installed"
    echo ""
    echo "Current versions:"
    asdf current 2>/dev/null || echo "No versions set"
    echo ""
    echo "asdf is ready to use!"
}

# Install common development tools via asdf
krun::apply::asdf::install_common_tools() {
    echo "Installing common development tools via asdf..."

    # Define tools and their preferred versions
    local tools=(
        "nodejs:latest"
        "python:3.11.7"
        "ruby:3.2.0"
        "golang:1.21.6"
        "java:openjdk-11.0.2"
    )

    for tool_version in "${tools[@]}"; do
        local tool="${tool_version%:*}"
        local version="${tool_version#*:}"

        echo "Processing $tool..."

        # Add plugin if not exists
        if ! asdf plugin list 2>/dev/null | grep -q "^${tool}$"; then
            echo "Adding $tool plugin..."
            case $tool in
            nodejs)
                asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
                ;;
            python)
                asdf plugin add python https://github.com/asdf-community/asdf-python.git
                ;;
            ruby)
                asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
                ;;
            golang)
                asdf plugin add golang https://github.com/kennyp/asdf-golang.git
                ;;
            java)
                asdf plugin add java https://github.com/halcyon/asdf-java.git
                ;;
            *)
                echo "Unknown tool: $tool"
                continue
                ;;
            esac
        else
            echo "✓ $tool plugin already installed"
        fi

        # Install version if not exists
        if [[ "$version" == "latest" ]]; then
            version=$(asdf latest $tool 2>/dev/null || echo "")
        fi

        if [[ -n "$version" ]]; then
            if ! asdf list $tool 2>/dev/null | grep -q "$version"; then
                echo "Installing $tool $version..."
                asdf install $tool $version || {
                    echo "⚠ Failed to install $tool $version"
                    continue
                }
            else
                echo "✓ $tool $version already installed"
            fi

            # Set as global version if no global version is set
            if ! asdf current $tool 2>/dev/null | grep -q "$version"; then
                echo "Setting $tool $version as global..."
                asdf global $tool $version || echo "⚠ Failed to set global version"
            fi
        else
            echo "⚠ Could not determine version for $tool"
        fi
    done

    # Update completions and reshim
    asdf reshim

    echo "✓ Common development tools installation completed"
}

# run main
krun::apply::asdf::run "$@"
