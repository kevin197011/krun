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
    krun::get::ipaddr::common
}

# debian code
krun::get::ipaddr::debian() {
    krun::get::ipaddr::common
}

# mac code
krun::get::ipaddr::mac() {
    krun::get::ipaddr::common
}

# common code
krun::get::ipaddr::common() {
    local ips=$(hostname -I)
    echo ${ips%% *}
}

# run main
krun::get::ipaddr::run "$@"