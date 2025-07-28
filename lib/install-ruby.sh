#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-ruby.sh | bash

# vars
ruby_version=${ruby_version:-3.2.0}

# run code
krun::install::ruby::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::ruby::centos() {
    echo "Installing Ruby on CentOS/RHEL..."
    krun::install::ruby::common
}

# debian code
krun::install::ruby::debian() {
    echo "Installing Ruby on Debian/Ubuntu..."
    krun::install::ruby::common
}

# mac code
krun::install::ruby::mac() {
    echo "Installing Ruby on macOS..."
    krun::install::ruby::common
}

# common code
krun::install::ruby::common() {
    echo "Installing Ruby ${ruby_version} via asdf..."

    if ! command -v asdf >/dev/null 2>&1; then
        echo "asdf not found. Please install asdf first:"
        echo "curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-asdf.sh | bash"
        return 1
    fi

    asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git || echo "Ruby plugin already installed"
    asdf plugin-update ruby || true

    echo "Installing Ruby ${ruby_version}..."
    asdf install ruby ${ruby_version} || {
        echo "Failed to install Ruby ${ruby_version}, trying latest stable..."
        latest_version=$(asdf latest ruby 3.2 2>/dev/null || echo "3.2.0")
        asdf install ruby ${latest_version}
        asdf global ruby ${latest_version}
    }

    asdf global ruby ${ruby_version} || asdf global ruby $(asdf latest ruby 3.2 2>/dev/null || echo "3.2.0")
    asdf reshim ruby || true

    krun::install::ruby::verify_installation
}

# Verify Ruby installation
krun::install::ruby::verify_installation() {
    echo "Verifying Ruby installation..."

    if command -v ruby >/dev/null 2>&1; then
        echo "✓ ruby command is available"
        ruby --version
    else
        echo "✗ ruby command not found"
        return 1
    fi

    if command -v gem >/dev/null 2>&1; then
        echo "✓ gem command is available"
        gem --version
    else
        echo "✗ gem command not found"
    fi

    if command -v bundle >/dev/null 2>&1; then
        echo "✓ bundler is available"
        bundle --version
    else
        echo "Installing bundler..."
        gem install bundler || echo "✗ Failed to install bundler"
    fi

    echo "Testing Ruby functionality..."
    ruby -e "puts 'Ruby #{RUBY_VERSION} is working!'" || echo "✗ Ruby test failed"

    echo "Installing common gems..."
    gem install rake json || echo "⚠ Failed to install common gems"

    echo "Ruby installation verification completed."
    echo ""
    echo "Ruby is ready to use!"
    echo "Try: ruby --version"
    echo "Create Gemfile: bundle init"
    echo "Install gems: bundle install"
}

# run main
krun::install::ruby::run "$@"
