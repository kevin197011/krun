#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-python3.sh | bash

# vars
python_version=${python_version:-3.11.0}

# run code
krun::install::python3::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::python3::centos() {
    echo "Installing Python3 dependencies on CentOS/RHEL..."

    # Install EPEL repository if not already installed
    yum install -y epel-release || true

    # Install development tools and dependencies
    yum groupinstall -y "Development Tools" || yum install -y gcc make
    yum install -y \
        openssl-devel \
        bzip2-devel \
        libffi-devel \
        xz-devel \
        sqlite-devel \
        readline-devel \
        tk-devel \
        gdbm-devel \
        libuuid-devel \
        ncurses-devel

    # Install Python3 from package manager as fallback
    yum install -y python3 python3-pip python3-devel || true

    krun::install::python3::common
}

# debian code
krun::install::python3::debian() {
    echo "Installing Python3 dependencies on Debian/Ubuntu..."

    # Update package lists
    apt-get update -y

    # Install build dependencies
    apt-get install -y \
        build-essential \
        libssl-dev \
        libbz2-dev \
        libffi-dev \
        liblzma-dev \
        libsqlite3-dev \
        libreadline-dev \
        tk-dev \
        libgdbm-dev \
        libc6-dev \
        libncurses5-dev \
        libnss3-dev \
        zlib1g-dev \
        curl \
        wget \
        git

    # Install Python3 from package manager
    apt-get install -y python3 python3-pip python3-venv python3-dev

    krun::install::python3::common
}

# mac code
krun::install::python3::mac() {
    echo "Installing Python3 on macOS..."

    # Check if Homebrew is available
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Installing Python3 via asdf..."
        krun::install::python3::common
        return
    fi

    # Install dependencies via Homebrew
    brew install openssl readline sqlite3 xz zlib

    # Install Python3 via Homebrew as primary method
    brew install python@3.11 || brew install python3

    # Also install via asdf as backup
    krun::install::python3::common
}

# common code
krun::install::python3::common() {
    echo "Installing Python ${python_version} via asdf..."

    # Check if asdf is available
    if ! command -v asdf >/dev/null 2>&1; then
        echo "asdf not found. Installing system Python packages only..."
        krun::install::python3::verify_installation
        return
    fi

    # Install Python plugin for asdf
    asdf plugin-add python || echo "Python plugin already installed"

    # Update plugin
    asdf plugin-update python || true

    # Install specific Python version
    echo "Installing Python ${python_version}..."
    asdf install python ${python_version} || {
        echo "Failed to install Python ${python_version}, trying latest stable..."
        latest_version=$(asdf latest python 3.11 2>/dev/null || echo "3.11.7")
        asdf install python ${latest_version}
        asdf global python ${latest_version}
    }

    # Set global version
    asdf global python ${python_version} || asdf global python $(asdf latest python 3.11 2>/dev/null || echo "3.11.7")

    # Refresh shell
    asdf reshim python || true

    krun::install::python3::verify_installation
}

# Verify Python installation
krun::install::python3::verify_installation() {
    echo "Verifying Python installation..."

    # Check Python3 command
    if command -v python3 >/dev/null 2>&1; then
        echo "✓ python3 is available"
        python3 --version
    else
        echo "✗ python3 command not found"
    fi

    # Check python command
    if command -v python >/dev/null 2>&1; then
        echo "✓ python is available"
        python --version
    else
        echo "✗ python command not found"
    fi

    # Check pip3
    if command -v pip3 >/dev/null 2>&1; then
        echo "✓ pip3 is available"
        pip3 --version
    else
        echo "✗ pip3 not found"
    fi

    # Check pip
    if command -v pip >/dev/null 2>&1; then
        echo "✓ pip is available"
        pip --version
    else
        echo "✗ pip not found"
    fi

    # Try to import some common modules
    echo "Testing Python functionality..."
    python3 -c "import sys; print(f'Python {sys.version}')" || echo "✗ Python3 test failed"
    python3 -c "import ssl; print('✓ SSL module available')" || echo "✗ SSL module not available"
    python3 -c "import sqlite3; print('✓ SQLite3 module available')" || echo "✗ SQLite3 module not available"

    echo "Python installation verification completed."
}

# run main
krun::install::python3::run "$@"
