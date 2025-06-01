#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/check-system_resources.sh | bash

# vars

# run code
krun::check::system_resources::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::check::system_resources::centos() {
    echo "=== System Resources Information (CentOS/RHEL) ==="
    echo
    echo "------ IP Address ------"
    hostname -I 2>/dev/null || ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1

    echo
    echo "------ CPU Information ------"
    if command -v lscpu >/dev/null 2>&1; then
        lscpu | grep -E 'Model name|Socket|Core|Thread|CPU\(s\):'
    else
        cat /proc/cpuinfo | grep -E 'model name|cpu cores|siblings' | head -n 3
    fi

    echo
    echo "------ Memory Usage ------"
    free -h

    echo
    echo "------ Disk Usage ------"
    df -h | grep -E '^/dev|Filesystem'

    echo
    echo "------ Block Devices ------"
    if command -v lsblk >/dev/null 2>&1; then
        lsblk
    else
        fdisk -l 2>/dev/null | grep -E '^Disk /dev'
    fi

    echo
    echo "------ System Load ------"
    uptime

    echo
    echo "------ Running Processes ------"
    ps aux | head -n 10
}

# debian code
krun::check::system_resources::debian() {
    echo "=== System Resources Information (Debian/Ubuntu) ==="
    echo
    echo "------ IP Address ------"
    hostname -I 2>/dev/null || ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1

    echo
    echo "------ CPU Information ------"
    if command -v lscpu >/dev/null 2>&1; then
        lscpu | grep -E 'Model name|Socket|Core|Thread|CPU\(s\):'
    else
        cat /proc/cpuinfo | grep -E 'model name|cpu cores|siblings' | head -n 3
    fi

    echo
    echo "------ Memory Usage ------"
    free -h

    echo
    echo "------ Disk Usage ------"
    df -h | grep -E '^/dev|Filesystem'

    echo
    echo "------ Block Devices ------"
    if command -v lsblk >/dev/null 2>&1; then
        lsblk
    else
        fdisk -l 2>/dev/null | grep -E '^Disk /dev'
    fi

    echo
    echo "------ System Load ------"
    uptime

    echo
    echo "------ Running Processes ------"
    ps aux | head -n 10

    echo
    echo "------ Network Interfaces ------"
    ip addr show | grep -E '^[0-9]+:|inet '
}

# mac code
krun::check::system_resources::mac() {
    echo "=== System Resources Information (macOS) ==="
    echo
    echo "------ IP Address ------"
    ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}'

    echo
    echo "------ CPU Information ------"
    sysctl -n machdep.cpu.brand_string
    echo "CPU Cores: $(sysctl -n hw.physicalcpu)"
    echo "Logical CPUs: $(sysctl -n hw.logicalcpu)"

    echo
    echo "------ Memory Information ------"
    echo "Total Memory: $(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024)) GB"
    vm_stat | head -n 5

    echo
    echo "------ Disk Usage ------"
    df -h | grep -E '^/dev|Filesystem'

    echo
    echo "------ System Load ------"
    uptime

    echo
    echo "------ Running Processes ------"
    ps aux | head -n 10

    echo
    echo "------ macOS Version ------"
    sw_vers
}

# common code
krun::check::system_resources::common() {
    echo "=== Additional System Information ==="
    echo
    echo "------ OS Information ------"
    if [[ -f /etc/os-release ]]; then
        grep -E '^NAME=|^VERSION=' /etc/os-release
    elif command -v sw_vers >/dev/null 2>&1; then
        sw_vers
    else
        uname -a
    fi

    echo
    echo "------ Kernel Information ------"
    uname -r

    echo
    echo "------ System Uptime ------"
    uptime
}

# run main
krun::check::system_resources::run "$@"
