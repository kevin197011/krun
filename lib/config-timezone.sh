#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-timezone.sh | bash

# vars
TIMEZONE="Asia/Hong_Kong"

# run code
krun::config::timezone::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::timezone::centos() {
    echo "Setting timezone to $TIMEZONE on CentOS/RHEL..."

    # Install tzdata if not present
    yum install -y tzdata >/dev/null 2>&1 || dnf install -y tzdata >/dev/null 2>&1 || true

    # Set timezone using timedatectl (preferred method)
    if command -v timedatectl >/dev/null 2>&1; then
        timedatectl set-timezone "$TIMEZONE"
    else
        # Fallback: symlink method
        ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
        echo "ZONE=$TIMEZONE" >/etc/sysconfig/clock
    fi

    echo "✓ Timezone set to $TIMEZONE"
    krun::config::timezone::common
}

# debian code
krun::config::timezone::debian() {
    echo "Setting timezone to $TIMEZONE on Debian/Ubuntu..."

    # Install tzdata if not present
    DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata >/dev/null 2>&1 || true

    # Set timezone using timedatectl (preferred method)
    if command -v timedatectl >/dev/null 2>&1; then
        timedatectl set-timezone "$TIMEZONE"
    else
        # Fallback: dpkg-reconfigure method
        echo "$TIMEZONE" >/etc/timezone
        dpkg-reconfigure -f noninteractive tzdata >/dev/null 2>&1 || true
        ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    fi

    echo "✓ Timezone set to $TIMEZONE"
    krun::config::timezone::common
}

# mac code
krun::config::timezone::mac() {
    echo "Setting timezone to $TIMEZONE on macOS..."

    # macOS uses systemsetup command
    if command -v systemsetup >/dev/null 2>&1; then
        sudo systemsetup -settimezone "$TIMEZONE" >/dev/null 2>&1 || {
            echo "⚠ Failed to set timezone. You may need to run: sudo systemsetup -settimezone $TIMEZONE"
        }
    else
        echo "⚠ systemsetup command not found. Please set timezone manually in System Preferences."
    fi

    echo "✓ Timezone set to $TIMEZONE"
    krun::config::timezone::common
}

# common code
krun::config::timezone::common() {
    echo "Verifying timezone configuration..."

    # Display current timezone
    if command -v timedatectl >/dev/null 2>&1; then
        echo "Current timezone: $(timedatectl | grep 'Time zone' | awk '{print $3}')"
    elif [[ -f /etc/timezone ]]; then
        echo "Current timezone: $(cat /etc/timezone)"
    elif [[ -L /etc/localtime ]]; then
        echo "Current timezone: $(readlink /etc/localtime | sed 's|.*/zoneinfo/||')"
    fi

    # Display current date and time
    echo "Current date and time: $(date)"
    echo "Timezone configuration completed."
}

# run main
krun::config::timezone::run "$@"
