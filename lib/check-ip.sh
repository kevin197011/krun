#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/check-ip.sh | bash

# vars
show_public_ip=${show_public_ip:-true}

# run code
krun::check::ip::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::check::ip::centos() {
    echo "Checking IP information on CentOS/RHEL..."
    krun::check::ip::common
}

# debian code
krun::check::ip::debian() {
    echo "Checking IP information on Debian/Ubuntu..."
    krun::check::ip::common
}

# mac code
krun::check::ip::mac() {
    echo "Checking IP information on macOS..."
    krun::check::ip::common
}

# get local IPs
krun::check::ip::get_local_ips() {
    if command -v hostname >/dev/null; then
        hostname -I 2>/dev/null | tr ' ' '\n' | grep -v '^$'
    elif command -v ip >/dev/null; then
        ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1
    elif [[ "$(uname)" == "Darwin" ]]; then
        ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}'
    fi
}

# get primary IP
krun::check::ip::get_primary_ip() {
    if command -v ip >/dev/null; then
        ip route get 8.8.8.8 2>/dev/null | grep -Po '(?<=src )[0-9.]+' | head -1
    elif [[ "$(uname)" == "Darwin" ]]; then
        route get default 2>/dev/null | grep interface | awk '{print $2}' | xargs ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -1
    fi
}

# get public IP
krun::check::ip::get_public_ip() {
    local services=("https://ipinfo.io/ip" "https://icanhazip.com" "https://ifconfig.me")

    for service in "${services[@]}"; do
        if command -v curl >/dev/null; then
            local ip=$(curl -s --connect-timeout 5 --max-time 10 "$service" 2>/dev/null | tr -d '\n\r')
            [[ -n "$ip" && "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && echo "$ip" && return 0
        elif command -v wget >/dev/null; then
            local ip=$(wget -qO- --timeout=10 "$service" 2>/dev/null | tr -d '\n\r')
            [[ -n "$ip" && "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && echo "$ip" && return 0
        fi
    done
    return 1
}

# get gateway
krun::check::ip::get_gateway() {
    if command -v ip >/dev/null; then
        ip route | grep default | awk '{print $3}' | head -1
    elif [[ "$(uname)" == "Darwin" ]]; then
        route -n get default 2>/dev/null | grep gateway | awk '{print $2}'
    fi
}

# common code
krun::check::ip::common() {
    echo "=== IP Address Information ==="
    echo ""

    # Local IP addresses
    echo "Local IP addresses:"
    krun::check::ip::get_local_ips | while read ip; do
        echo "  $ip"
    done
    echo ""

    # Primary local IP
    echo "Primary local IP:"
    local primary_ip=$(krun::check::ip::get_primary_ip)
    echo "  ${primary_ip:-'Unknown'}"
    echo ""

    # Public IP
    if [[ "$show_public_ip" == "true" ]]; then
        echo "Public IP address:"
        local public_ip=$(krun::check::ip::get_public_ip)
        if [[ -n "$public_ip" ]]; then
            echo "  $public_ip"
        else
            echo "  Unable to determine public IP"
        fi
        echo ""
    fi

    # Network interfaces
    echo "Network interfaces:"
    if command -v ip >/dev/null; then
        ip addr show | grep -E '^[0-9]+:|inet ' | while read line; do
            if [[ "$line" =~ ^[0-9]+: ]]; then
                echo "  $(echo "$line" | cut -d: -f2 | awk '{print $1}'):"
            else
                echo "    $(echo "$line" | awk '{print $2}')"
            fi
        done
    elif [[ "$(uname)" == "Darwin" ]]; then
        ifconfig | grep -E '^[a-z0-9]+:|inet ' | while read line; do
            if [[ "$line" =~ ^[a-z0-9]+: ]]; then
                echo "  $(echo "$line" | cut -d: -f1):"
            else
                echo "    $(echo "$line" | awk '{print $2}')"
            fi
        done
    fi
    echo ""

    # DNS servers
    echo "DNS servers:"
    if [[ -f /etc/resolv.conf ]]; then
        grep '^nameserver' /etc/resolv.conf | awk '{print "  " $2}'
    else
        echo "  DNS information not available"
    fi
    echo ""

    # Gateway
    echo "Default gateway:"
    local gateway=$(krun::check::ip::get_gateway)
    echo "  ${gateway:-'Unknown'}"
    echo ""

    # Hostname
    echo "Hostname: $(hostname 2>/dev/null || echo 'unknown')"
    echo ""
    echo "IP check completed."
}

# run main
krun::check::ip::run "$@"
