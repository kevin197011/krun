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
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::ruby::centos() {
    echo "Installing Ruby on CentOS/RHEL..."

    # Install EPEL repository
    yum install -y epel-release

    # Install development tools and dependencies
    yum groupinstall -y "Development Tools" || yum install -y gcc make
    yum install -y \
        openssl-devel \
        libyaml-devel \
        libffi-devel \
        readline-devel \
        zlib-devel \
        gdbm-devel \
        ncurses-devel \
        git \
        curl

    # Install Ruby from package manager as fallback
    yum install -y ruby ruby-devel rubygems || true

    krun::install::ruby::common
}

# debian code
krun::install::ruby::debian() {
    echo "Installing Ruby on Debian/Ubuntu..."

    # Update package lists
    apt-get update

    # Install build dependencies
    apt-get install -y \
        build-essential \
        libssl-dev \
        libyaml-dev \
        libffi-dev \
        libreadline-dev \
        zlib1g-dev \
        libgdbm-dev \
        libncurses5-dev \
        autoconf \
        bison \
        libtool \
        git \
        curl \
        wget

    # Install Ruby from package manager
    apt-get install -y ruby ruby-dev rubygems

    krun::install::ruby::common
}

# mac code
krun::install::ruby::mac() {
    echo "Installing Ruby on macOS..."

    # Install via Homebrew if available
    if command -v brew >/dev/null 2>&1; then
        brew install ruby || brew upgrade ruby || true
        brew install openssl readline libyaml libffi
    else
        echo "Homebrew not found, using asdf only..."
    fi

    krun::install::ruby::common
}

# common code
krun::install::ruby::common() {
    echo "Installing Ruby ${ruby_version} via asdf..."

    # Check if asdf is available
    if ! command -v asdf >/dev/null 2>&1; then
        echo "asdf not found. Installing Ruby manually..."
        krun::install::ruby::manual_install
        return
    fi

    # Install Ruby plugin for asdf
    asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git || echo "Ruby plugin already installed"

    # Update plugin
    asdf plugin-update ruby || true

    # Install specific Ruby version
    echo "Installing Ruby ${ruby_version}..."
    asdf install ruby ${ruby_version} || {
        echo "Failed to install Ruby ${ruby_version}, trying latest stable..."
        latest_version=$(asdf latest ruby 3.2 2>/dev/null || echo "3.2.0")
        asdf install ruby ${latest_version}
        asdf global ruby ${latest_version}
    }

    # Set global version
    asdf global ruby ${ruby_version} || asdf global ruby $(asdf latest ruby 3.2 2>/dev/null || echo "3.2.0")

    # Refresh shell
    asdf reshim ruby || true

    krun::install::ruby::verify_installation
}

# Manual Ruby installation
krun::install::ruby::manual_install() {
    echo "Installing Ruby manually..."

    local ruby_ver="${ruby_version}"
    local ruby_url="https://cache.ruby-lang.org/pub/ruby/${ruby_ver%.*}/ruby-${ruby_ver}.tar.gz"
    local install_dir="/usr/local"

    echo "Downloading Ruby ${ruby_ver}..."

    # Download and compile Ruby
    cd /tmp
    curl -L -o ruby.tar.gz "${ruby_url}"
    tar -xzf ruby.tar.gz
    cd ruby-${ruby_ver}

    # Configure and compile
    ./configure --prefix=${install_dir}
    make -j$(nproc 2>/dev/null || echo 4)
    make install

    # Clean up
    cd /
    rm -rf /tmp/ruby.tar.gz /tmp/ruby-${ruby_ver}

    echo "✓ Ruby installed manually to ${install_dir}"
    krun::install::ruby::verify_installation
}

# Verify Ruby installation
krun::install::ruby::verify_installation() {
    echo "Verifying Ruby installation..."

    # Check ruby command
    if command -v ruby >/dev/null 2>&1; then
        echo "✓ ruby command is available"
        ruby --version
    else
        echo "✗ ruby command not found"
        return 1
    fi

    # Check gem command
    if command -v gem >/dev/null 2>&1; then
        echo "✓ gem command is available"
        gem --version
    else
        echo "✗ gem command not found"
    fi

    # Check bundler
    if command -v bundle >/dev/null 2>&1; then
        echo "✓ bundler is available"
        bundle --version
    else
        echo "Installing bundler..."
        gem install bundler || echo "✗ Failed to install bundler"
    fi

    # Test Ruby functionality
    echo "Testing Ruby functionality..."
    ruby -e "puts 'Ruby #{RUBY_VERSION} is working!'" || echo "✗ Ruby test failed"

    # Install some common gems
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
