#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/get-host_info.sh | bash

# vars

# run code
krun::get::host_info::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::get::host_info::centos() {
    echo "Getting host information on CentOS/RHEL..."
    krun::get::host_info::common
}

# debian code
krun::get::host_info::debian() {
    echo "Getting host information on Debian/Ubuntu..."
    krun::get::host_info::common
}

# mac code
krun::get::host_info::mac() {
    echo "Getting host information on macOS..."
    krun::get::host_info::common
}

# common code
krun::get::host_info::common() {
    echo "=== Host Information ==="
    echo ""

    # Hostname
    echo "Hostname: $(hostname 2>/dev/null || echo 'unknown')"
    echo "FQDN: $(hostname -f 2>/dev/null || hostname 2>/dev/null || echo 'unknown')"

    # Operating System
    echo ""
    echo "Operating System:"
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "  Name: ${PRETTY_NAME:-${NAME:-'Unknown'}}"
        echo "  Version: ${VERSION:-'Unknown'}"
        echo "  ID: ${ID:-'Unknown'}"
    elif [[ "$(uname)" == "Darwin" ]]; then
        echo "  Name: macOS"
        if command -v sw_vers >/dev/null 2>&1; then
            echo "  Version: $(sw_vers -productVersion)"
            echo "  Build: $(sw_vers -buildVersion)"
        fi
    else
        echo "  $(uname -a)"
    fi

    # Kernel
    echo ""
    echo "Kernel:"
    echo "  Version: $(uname -r)"
    echo "  Architecture: $(uname -m)"

    # CPU Information
    echo ""
    echo "CPU Information:"
    if [[ -f /proc/cpuinfo ]]; then
        local cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//')
        local cpu_cores=$(grep "cpu cores" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ *//')
        local cpu_threads=$(grep "processor" /proc/cpuinfo | wc -l)
        echo "  Model: ${cpu_model:-'Unknown'}"
        echo "  Cores: ${cpu_cores:-'Unknown'}"
        echo "  Threads: ${cpu_threads:-'Unknown'}"
    elif [[ "$(uname)" == "Darwin" ]]; then
        echo "  Model: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'Unknown')"
        echo "  Cores: $(sysctl -n hw.physicalcpu 2>/dev/null || echo 'Unknown')"
        echo "  Threads: $(sysctl -n hw.logicalcpu 2>/dev/null || echo 'Unknown')"
    fi

    # Memory Information
    echo ""
    echo "Memory Information:"
    if command -v free >/dev/null 2>&1; then
        local mem_info=$(free -h | grep "^Mem:")
        echo "  Total: $(echo $mem_info | awk '{print $2}')"
        echo "  Used: $(echo $mem_info | awk '{print $3}')"
        echo "  Available: $(echo $mem_info | awk '{print $7}')"
    elif [[ "$(uname)" == "Darwin" ]]; then
        local total_mem=$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))
        echo "  Total: ${total_mem}GB"
        if command -v vm_stat >/dev/null 2>&1; then
            local page_size=$(vm_stat | grep "page size" | awk '{print $8}')
            local free_pages=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
            local free_mem=$((free_pages * page_size / 1024 / 1024))
            echo "  Free: ${free_mem}MB"
        fi
    fi

    # Disk Information
    echo ""
    echo "Disk Usage:"
    df -h | grep -E '^/dev|^Filesystem' | head -10

    # Network Information
    echo ""
    echo "Network Interfaces:"
    if command -v ip >/dev/null 2>&1; then
        ip addr show | grep -E '^[0-9]+:|inet ' | while read line; do
            if [[ "$line" =~ ^[0-9]+: ]]; then
                echo "  $(echo "$line" | cut -d: -f2 | awk '{print $1}'):"
            else
                echo "    $(echo "$line" | awk '{print $2}')"
            fi
        done | head -20
    elif [[ "$(uname)" == "Darwin" ]]; then
        ifconfig | grep -E '^[a-z0-9]+:|inet ' | while read line; do
            if [[ "$line" =~ ^[a-z0-9]+: ]]; then
                echo "  $(echo "$line" | cut -d: -f1):"
            else
                echo "    $(echo "$line" | awk '{print $2}')"
            fi
        done | head -20
    fi

    # Uptime
    echo ""
    echo "System Uptime:"
    echo "  $(uptime)"

    # Load Average
    echo ""
    echo "Load Average:"
    if [[ -f /proc/loadavg ]]; then
        local load=$(cat /proc/loadavg)
        echo "  1min: $(echo $load | awk '{print $1}')"
        echo "  5min: $(echo $load | awk '{print $2}')"
        echo "  15min: $(echo $load | awk '{print $3}')"
    elif [[ "$(uname)" == "Darwin" ]]; then
        local load=$(uptime | awk '{print $(NF-2), $(NF-1), $NF}' | tr -d ',')
        echo "  1min: $(echo $load | awk '{print $1}')"
        echo "  5min: $(echo $load | awk '{print $2}')"
        echo "  15min: $(echo $load | awk '{print $3}')"
    fi

    # Running Processes
    echo ""
    echo "Top Processes (by CPU):"
    if command -v ps >/dev/null 2>&1; then
        ps aux --sort=-%cpu | head -6
    fi

    # Services (Linux only)
    if command -v systemctl >/dev/null 2>&1; then
        echo ""
        echo "Active Services:"
        systemctl list-units --type=service --state=active | head -10
    fi

    # Date and Timezone
    echo ""
    echo "Date and Time:"
    echo "  Current: $(date)"
    echo "  Timezone: $(date +%Z %z)"

    echo ""
    echo "Host information collection completed."
}

# run main
krun::get::host_info::run "$@"
