#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/disable-firewall-selinux.sh | bash

# vars

# run code
krun::disable::firewall_selinux::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::disable::firewall_selinux::centos() {
    krun::disable::firewall_selinux::common
}

# debian code
krun::disable::firewall_selinux::debian() {
    krun::disable::firewall_selinux::common
}

# mac code
krun::disable::firewall_selinux::mac() {
    echo "macOS doesn't use iptables/firewall/SELinux in the same way"
    echo "Skipping firewall and SELinux disable on macOS"
}

# common code
krun::disable::firewall_selinux::common() {
    [[ "$OSTYPE" != "darwin"* ]] && [[ $EUID -ne 0 ]] && echo "✗ Please run as root" && return 1

    echo "Disabling firewall and SELinux..."

    # Disable firewalld
    if command -v firewall-cmd >/dev/null 2>&1; then
        echo "Stopping and disabling firewalld..."
        systemctl stop firewalld 2>/dev/null || true
        systemctl disable firewalld 2>/dev/null || true
        echo "✓ firewalld disabled"
    fi

    # Disable ufw
    if command -v ufw >/dev/null 2>&1; then
        echo "Stopping and disabling ufw..."
        ufw --force disable 2>/dev/null || true
        systemctl stop ufw 2>/dev/null || true
        systemctl disable ufw 2>/dev/null || true
        echo "✓ ufw disabled"
    fi

    # Disable iptables
    if command -v iptables >/dev/null 2>&1; then
        echo "Flushing iptables rules..."
        iptables -F 2>/dev/null || true
        iptables -X 2>/dev/null || true
        iptables -t nat -F 2>/dev/null || true
        iptables -t nat -X 2>/dev/null || true
        iptables -t mangle -F 2>/dev/null || true
        iptables -t mangle -X 2>/dev/null || true
        iptables -P INPUT ACCEPT 2>/dev/null || true
        iptables -P FORWARD ACCEPT 2>/dev/null || true
        iptables -P OUTPUT ACCEPT 2>/dev/null || true
        echo "✓ iptables rules flushed"

        # Stop iptables service if exists
        if systemctl list-unit-files | grep -q iptables.service; then
            systemctl stop iptables 2>/dev/null || true
            systemctl disable iptables 2>/dev/null || true
            echo "✓ iptables service disabled"
        fi
    fi

    # Disable ip6tables
    if command -v ip6tables >/dev/null 2>&1; then
        echo "Flushing ip6tables rules..."
        ip6tables -F 2>/dev/null || true
        ip6tables -X 2>/dev/null || true
        ip6tables -t mangle -F 2>/dev/null || true
        ip6tables -t mangle -X 2>/dev/null || true
        ip6tables -P INPUT ACCEPT 2>/dev/null || true
        ip6tables -P FORWARD ACCEPT 2>/dev/null || true
        ip6tables -P OUTPUT ACCEPT 2>/dev/null || true
        echo "✓ ip6tables rules flushed"
    fi

    # Disable SELinux
    if command -v getenforce >/dev/null 2>&1; then
        local selinux_status=$(getenforce 2>/dev/null || echo "Disabled")
        if [[ "$selinux_status" != "Disabled" ]]; then
            echo "Disabling SELinux..."
            # Set to permissive mode first
            setenforce 0 2>/dev/null || true
            # Permanently disable SELinux
            if [[ -f /etc/selinux/config ]]; then
                sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
                echo "✓ SELinux disabled (requires reboot to take full effect)"
            else
                echo "⚠ SELinux config file not found, set to permissive mode"
            fi
        else
            echo "✓ SELinux already disabled"
        fi
    fi

    echo ""
    echo "✓ Firewall and SELinux disabled"
    echo "Note: SELinux changes require a reboot to take full effect"
}

# run main
krun::disable::firewall_selinux::run "$@"
