#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-elixir.sh | bash

# vars
elixir_version=${elixir_version:-1.15.7}
erlang_version=${erlang_version:-26.1.2}

# run code
krun::install::elixir::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::elixir::centos() {
    echo "Installing Elixir on CentOS/RHEL..."

    # Install EPEL repository
    yum install -y epel-release

    # Install Erlang/OTP from EPEL
    yum install -y erlang elixir || {
        echo "Package installation failed, using asdf..."
    }

    krun::install::elixir::common
}

# debian code
krun::install::elixir::debian() {
    echo "Installing Elixir on Debian/Ubuntu..."

    # Update package lists
    apt-get update

    # Install Erlang and Elixir from package manager
    apt-get install -y erlang elixir || {
        echo "Package installation failed, using asdf..."
    }

    krun::install::elixir::common
}

# mac code
krun::install::elixir::mac() {
    echo "Installing Elixir on macOS..."

    if command -v brew >/dev/null 2>&1; then
        # Install Erlang/OTP and Elixir via Homebrew
        brew install erlang elixir
        echo "✓ Elixir installed via Homebrew"
        krun::install::elixir::verify_installation
        return
    else
        echo "Homebrew not found, using asdf..."
        krun::install::elixir::common
    fi
}

# common code
krun::install::elixir::common() {
    echo "Installing Elixir via asdf..."

    # Check if asdf is available
    if ! command -v asdf >/dev/null 2>&1; then
        echo "asdf not found. Installing asdf first..."
        curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-asdf.sh | bash

        # Source asdf
        if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
            source "$HOME/.asdf/asdf.sh"
        fi

        if ! command -v asdf >/dev/null 2>&1; then
            echo "✗ asdf installation failed"
            return 1
        fi
    fi

    # Install Erlang plugin
    echo "Adding Erlang plugin..."
    asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git || echo "Erlang plugin already installed"

    # Install Elixir plugin
    echo "Adding Elixir plugin..."
    asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git || echo "Elixir plugin already installed"

    # Install Erlang/OTP
    echo "Installing Erlang/OTP ${erlang_version}..."
    asdf install erlang ${erlang_version} || {
        echo "Failed to install Erlang ${erlang_version}, trying latest..."
        latest_erlang=$(asdf latest erlang 2>/dev/null || echo "26.1")
        asdf install erlang ${latest_erlang}
        asdf global erlang ${latest_erlang}
    }

    # Set global Erlang version
    asdf global erlang ${erlang_version} 2>/dev/null || asdf global erlang $(asdf latest erlang 2>/dev/null || echo "26.1")

    # Install Elixir
    echo "Installing Elixir ${elixir_version}..."
    asdf install elixir ${elixir_version} || {
        echo "Failed to install Elixir ${elixir_version}, trying latest..."
        latest_elixir=$(asdf latest elixir 2>/dev/null || echo "1.15")
        asdf install elixir ${latest_elixir}
        asdf global elixir ${latest_elixir}
    }

    # Set global Elixir version
    asdf global elixir ${elixir_version} 2>/dev/null || asdf global elixir $(asdf latest elixir 2>/dev/null || echo "1.15")

    # Refresh shell
    asdf reshim erlang || true
    asdf reshim elixir || true

    krun::install::elixir::verify_installation
}

# Verify Elixir installation
krun::install::elixir::verify_installation() {
    echo "Verifying Elixir installation..."

    # Check Erlang
    if command -v erl >/dev/null 2>&1; then
        echo "✓ Erlang is available"
        erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell
    else
        echo "✗ Erlang not found"
    fi

    # Check Elixir
    if command -v elixir >/dev/null 2>&1; then
        echo "✓ Elixir is available"
        elixir --version
    else
        echo "✗ Elixir not found"
        return 1
    fi

    # Check IEx (Interactive Elixir)
    if command -v iex >/dev/null 2>&1; then
        echo "✓ IEx (Interactive Elixir) is available"
        iex --version
    else
        echo "✗ IEx not found"
    fi

    # Check Mix (Elixir build tool)
    if command -v mix >/dev/null 2>&1; then
        echo "✓ Mix (build tool) is available"
        mix --version
    else
        echo "✗ Mix not found"
    fi

    # Test Elixir functionality
    echo "Testing Elixir functionality..."
    elixir -e 'IO.puts("Hello, Elixir! Version: #{System.version()}")' || echo "✗ Elixir test failed"

    echo ""
    echo "=== Elixir Installation Summary ==="
    echo "Erlang version: $(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null || echo 'Unknown')"
    echo "Elixir version: $(elixir --version | head -1)"
    echo "Mix version: $(mix --version 2>/dev/null || echo 'Unknown')"
    echo ""
    echo "Common Elixir commands:"
    echo "  elixir script.exs       - Run Elixir script"
    echo "  iex                     - Interactive Elixir shell"
    echo "  mix new my_app          - Create new Mix project"
    echo "  mix deps.get            - Get dependencies"
    echo "  mix compile             - Compile project"
    echo "  mix test                - Run tests"
    echo "  mix run                 - Run application"
    echo ""
    echo "Phoenix Framework:"
    echo "  mix archive.install hex phx_new  - Install Phoenix"
    echo "  mix phx.new my_web_app           - Create Phoenix app"
    echo ""
    echo "Elixir is ready to use!"
}

# run main
krun::install::elixir::run "$@"
