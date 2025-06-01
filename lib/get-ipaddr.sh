#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/get-ipaddr.sh | bash

# vars

# run code
krun::get::ipaddr::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::get::ipaddr::centos() {
    echo "=== IP Address Information (CentOS/RHEL) ==="

    # Get local IP addresses
    echo "Local IP addresses:"
    if command -v hostname >/dev/null 2>&1; then
        hostname -I 2>/dev/null | tr ' ' '\n' | grep -v '^$' | while read ip; do
            echo "  - $ip"
        done
    else
        ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print "  - " $2}' | cut -d/ -f1
    fi

    krun::get::ipaddr::common
}

# debian code
krun::get::ipaddr::debian() {
    echo "=== IP Address Information (Debian/Ubuntu) ==="

    # Get local IP addresses
    echo "Local IP addresses:"
    if command -v hostname >/dev/null 2>&1; then
        hostname -I 2>/dev/null | tr ' ' '\n' | grep -v '^$' | while read ip; do
            echo "  - $ip"
        done
    else
        ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print "  - " $2}' | cut -d/ -f1
    fi

    krun::get::ipaddr::common
}

# mac code
krun::get::ipaddr::mac() {
    echo "=== IP Address Information (macOS) ==="

    # Get local IP addresses
    echo "Local IP addresses:"
    ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{print "  - " $2}'

    krun::get::ipaddr::common
}

# common code
krun::get::ipaddr::common() {
    echo ""
    echo "Primary local IP:"

    # Get primary local IP address
    local primary_ip=""

    if command -v hostname >/dev/null 2>&1; then
        primary_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi

    if [[ -z "$primary_ip" ]]; then
        if command -v ip >/dev/null 2>&1; then
            primary_ip=$(ip route get 8.8.8.8 2>/dev/null | grep -Po '(?<=src )[0-9.]+' | head -1)
        fi
    fi

    if [[ -z "$primary_ip" ]] && [[ "$(uname)" == "Darwin" ]]; then
        primary_ip=$(route get default 2>/dev/null | grep interface | awk '{print $2}' | xargs ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -1)
    fi

    if [[ -n "$primary_ip" ]]; then
        echo "  $primary_ip"
    else
        echo "  Unable to determine primary IP"
    fi

    echo ""
    echo "Public IP address:"

    # Try multiple methods to get public IP
    local public_ip=""
    local services=(
        "https://ipinfo.io/ip"
        "https://icanhazip.com"
        "https://ifconfig.me"
        "https://api.ipify.org"
        "https://checkip.amazonaws.com"
    )

    for service in "${services[@]}"; do
        if command -v curl >/dev/null 2>&1; then
            public_ip=$(curl -s --connect-timeout 5 --max-time 10 "$service" 2>/dev/null | tr -d '\n\r' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')
        elif command -v wget >/dev/null 2>&1; then
            public_ip=$(wget -qO- --timeout=10 "$service" 2>/dev/null | tr -d '\n\r' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')
        fi

        if [[ -n "$public_ip" ]]; then
            echo "  $public_ip (via ${service})"
            break
        fi
    done

    if [[ -z "$public_ip" ]]; then
        echo "  Unable to determine public IP (check internet connection)"
    fi

    echo ""
    echo "Network interfaces:"

    # Show network interfaces
    if command -v ip >/dev/null 2>&1; then
        ip addr show | grep -E '^[0-9]+:|inet ' | while read line; do
            if [[ "$line" =~ ^[0-9]+: ]]; then
                echo "  Interface: $(echo "$line" | cut -d: -f2 | awk '{print $1}')"
            elif [[ "$line" =~ inet ]]; then
                echo "    $(echo "$line" | awk '{print $2}')"
            fi
        done
    elif [[ "$(uname)" == "Darwin" ]]; then
        ifconfig | grep -E '^[a-z0-9]+:|inet ' | while read line; do
            if [[ "$line" =~ ^[a-z0-9]+: ]]; then
                echo "  Interface: $(echo "$line" | cut -d: -f1)"
            elif [[ "$line" =~ inet ]]; then
                echo "    $(echo "$line" | awk '{print $2}')"
            fi
        done
    else
        echo "  Network interface information not available"
    fi

    echo ""
    echo "DNS servers:"

    # Show DNS servers
    if [[ -f /etc/resolv.conf ]]; then
        grep '^nameserver' /etc/resolv.conf | awk '{print "  " $2}' || echo "  No nameservers found"
    else
        echo "  DNS information not available"
    fi

    # Additional network info
    echo ""
    echo "Additional network information:"

    # Default gateway
    if command -v ip >/dev/null 2>&1; then
        local gateway=$(ip route | grep default | awk '{print $3}' | head -1)
        if [[ -n "$gateway" ]]; then
            echo "  Default gateway: $gateway"
        fi
    elif [[ "$(uname)" == "Darwin" ]]; then
        local gateway=$(route -n get default 2>/dev/null | grep gateway | awk '{print $2}')
        if [[ -n "$gateway" ]]; then
            echo "  Default gateway: $gateway"
        fi
    fi

    # Hostname
    echo "  Hostname: $(hostname 2>/dev/null || echo 'unknown')"
}

# run main
krun::get::ipaddr::run "$@"
