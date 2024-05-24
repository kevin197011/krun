#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# vars

# run code
krun::get::host_info::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::get::host_info::centos() {
    # krun::get::host_info::common
    ips=$(hostname -I)
    cpus=$(lscpu | awk '/^CPU\(s\)/{print $2}')
    mem=$(free -h | awk '/Mem/{print $2}')

    echo "ip: ${ips%% *}"
    echo "cpus: ${cpus}"
    echo "mem: ${mem}"
    fdisk -l | awk '/Disk \/dev\/sd/{print $0}'
}

# debian code
krun::get::host_info::debian() {
    krun::get::host_info::common
}

# mac code
krun::get::host_info::mac() {
    krun::get::host_info::common
}

# common code
krun::get::host_info::common() {
    echo "${FUNCNAME}..."
}

# run main
krun::get::host_info::run "$@"
