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
    echo "------ IP 地址 ------"
    hostname -I

    echo "------ CPU 信息 ------"
    lscpu | grep -E 'Model name|Socket|Core|Thread'

    echo "------ 内存使用情况 ------"
    free -h

    echo "------ 磁盘使用情况 ------"
    df -h

    echo "------ 磁盘大小 ------"
    lsblk
}

# debian code
krun::check::system_resources::debian() {
    krun::check::system_resources::common
}

# mac code
krun::check::system_resources::mac() {
    krun::check::system_resources::common
}

# common code
krun::check::system_resources::common() {
    echo "${FUNCNAME}"
}

# run main
krun::check::system_resources::run "$@"
