#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/check-ip-quality.sh | bash

# vars
IP="${1:-}"
IPV4="${IPV4:-}"
IPV6="${IPV6:-}"

# run code
krun::check::ip_quality::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::check::ip_quality::centos() {
    krun::check::ip_quality::common
}

# debian code
krun::check::ip_quality::debian() {
    krun::check::ip_quality::common
}

# mac code
krun::check::ip_quality::mac() {
    krun::check::ip_quality::common
}

# get IP address
krun::check::ip_quality::get_ip() {
    local ip_type="$1"
    if [[ -n "$IP" ]]; then
        echo "$IP"
        return
    fi

    if [[ "$ip_type" == "4" ]]; then
        curl -s4 --connect-timeout 5 ifconfig.me 2>/dev/null ||
            curl -s4 --connect-timeout 5 ip.sb 2>/dev/null ||
            curl -s4 --connect-timeout 5 icanhazip.com 2>/dev/null ||
            echo ""
    else
        curl -s6 --connect-timeout 5 ifconfig.me 2>/dev/null ||
            curl -s6 --connect-timeout 5 ip.sb 2>/dev/null ||
            echo ""
    fi
}

# check media unlock
krun::check::ip_quality::check_media() {
    local service="$1"
    local ip_type="$2"

    case "$service" in
    "Netflix")
        local result
        result=$(curl -s"$ip_type" --connect-timeout 5 --max-time 10 "https://www.netflix.com/title/80018499" 2>/dev/null | grep -o "Netflix" | head -1 || echo "")
        [[ -n "$result" ]] && echo "Yes" || echo "No"
        ;;
    "YouTube")
        local result
        result=$(curl -s"$ip_type" --connect-timeout 5 --max-time 10 "https://www.youtube.com/premium" 2>/dev/null | grep -o "Premium" | head -1 || echo "")
        [[ -n "$result" ]] && echo "Yes" || echo "No"
        ;;
    "Disney")
        local result
        result=$(curl -s"$ip_type" --connect-timeout 5 --max-time 10 "https://www.disneyplus.com" 2>/dev/null | grep -o "Disney" | head -1 || echo "")
        [[ -n "$result" ]] && echo "Yes" || echo "No"
        ;;
    *)
        echo "No"
        ;;
    esac
}

# check IP info
krun::check::ip_quality::check_ipinfo() {
    local ip="$1"
    local ip_type="$2"

    echo "Checking IP information..."

    local api_url="http://ip-api.com/json/$ip?fields=status,message,country,countryCode,city,isp,org,as,query"
    local result
    result=$(curl -s --connect-timeout 5 "$api_url" 2>/dev/null || echo "")

    if echo "$result" | grep -q '"status":"success"'; then
        echo "Country: $(echo "$result" | grep -o '"country":"[^"]*' | cut -d'"' -f4)"
        echo "City: $(echo "$result" | grep -o '"city":"[^"]*' | cut -d'"' -f4)"
        echo "ISP: $(echo "$result" | grep -o '"isp":"[^"]*' | cut -d'"' -f4)"
        echo "ASN: $(echo "$result" | grep -o '"as":"[^"]*' | cut -d'"' -f4)"
    else
        echo "Failed to get IP information"
    fi
}

# common code
krun::check::ip_quality::common() {
    echo "IP Quality Check"
    echo "================"
    echo ""

    # Get IP addresses
    if [[ -z "$IP" ]]; then
        IPV4=$(krun::check::ip_quality::get_ip 4)
        IPV6=$(krun::check::ip_quality::get_ip 6)
    else
        IPV4="$IP"
        IPV6=""
    fi

    # Check IPv4
    if [[ -n "$IPV4" ]]; then
        echo "=== IPv4: $IPV4 ==="
        krun::check::ip_quality::check_ipinfo "$IPV4" 4
        echo ""

        echo "=== Media Unlock Test (IPv4) ==="
        echo "Netflix: $(krun::check::ip_quality::check_media "Netflix" 4)"
        echo "YouTube Premium: $(krun::check::ip_quality::check_media "YouTube" 4)"
        echo "Disney+: $(krun::check::ip_quality::check_media "Disney" 4)"
        echo ""
    fi

    # Check IPv6
    if [[ -n "$IPV6" ]]; then
        echo "=== IPv6: $IPV6 ==="
        krun::check::ip_quality::check_ipinfo "$IPV6" 6
        echo ""

        echo "=== Media Unlock Test (IPv6) ==="
        echo "Netflix: $(krun::check::ip_quality::check_media "Netflix" 6)"
        echo "YouTube Premium: $(krun::check::ip_quality::check_media "YouTube" 6)"
        echo "Disney+: $(krun::check::ip_quality::check_media "Disney" 6)"
        echo ""
    fi

    if [[ -z "$IPV4" ]] && [[ -z "$IPV6" ]]; then
        echo "Error: Unable to get IP address"
        exit 1
    fi
}

# run main
krun::check::ip_quality::run "$@"
