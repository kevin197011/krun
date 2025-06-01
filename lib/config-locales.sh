#!/usr/bin/env bash

# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-locales.sh | bash

# vars

# run code
krun::config::locales::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::locales::centos() {
    echo "Configuring locales on CentOS/RHEL..."

    # Install glibc-langpack for locale support
    yum install -y glibc-langpack-en glibc-locale-source glibc-all-langpacks || {
        # Fallback for older versions
        yum install -y glibc-common
    }

    # Set locale environment variables
    cat >/etc/locale.conf <<EOF
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
EOF

    # Set in current session
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

    # Update system locale
    if command -v localectl >/dev/null 2>&1; then
        localectl set-locale LANG=en_US.UTF-8
    fi

    echo "✓ Locales configured for CentOS/RHEL"
    krun::config::locales::common
}

# debian code
krun::config::locales::debian() {
    echo "Configuring locales on Debian/Ubuntu..."

    # Remove old locale packages to start clean
    apt-get purge -y locales || true
    apt-get purge -y language-pack-en || true

    # Install locale packages
    apt-get update
    apt-get install -y locales

    # Install language pack for Ubuntu
    apt-get install -y language-pack-en || true

    # Configure locale generation
    sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
    sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/g' /etc/locale.gen || true

    # Generate locales
    locale-gen

    # Set system locale
    if command -v localectl >/dev/null 2>&1; then
        localectl set-locale LANG=en_US.UTF-8
    else
        update-locale LANG=en_US.UTF-8
    fi

    echo "✓ Locales configured for Debian/Ubuntu"
    krun::config::locales::common
}

# mac code
krun::config::locales::mac() {
    echo "Configuring locales on macOS..."

    # macOS uses different locale system
    # Set locale environment variables in shell profile
    local shell_profile=""
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        shell_profile="$HOME/.zshrc"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        shell_profile="$HOME/.bash_profile"
    fi

    if [[ -n "$shell_profile" ]]; then
        cat >>"$shell_profile" <<EOF

# Locale configuration
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
EOF
        echo "✓ Locale environment variables added to $shell_profile"
    fi

    # Set for current session
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

    echo "✓ Locales configured for macOS"
    krun::config::locales::common
}

# common code
krun::config::locales::common() {
    echo "Verifying locale configuration..."

    # Display current locale settings
    echo "Current locale settings:"
    locale 2>/dev/null || echo "locale command not available"

    # Test locale functionality
    echo "Testing locale functionality..."
    date 2>/dev/null && echo "✓ Date command works with current locale"

    # Check if UTF-8 is supported
    if locale -a 2>/dev/null | grep -i "utf.*8" >/dev/null; then
        echo "✓ UTF-8 locales are available"
    else
        echo "⚠ UTF-8 locales may not be properly configured"
    fi

    echo "Locale configuration completed."
}

# run main
krun::config::locales::run "$@"
