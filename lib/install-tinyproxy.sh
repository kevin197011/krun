#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-tinyproxy.sh | bash

# vars

# run code
krun::install::tinyproxy::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::tinyproxy::centos() {
    krun::install::tinyproxy::common
    yum install -y epel-release
    yum update -y
    yum install -y tinyproxy
    systemctl enable tinyproxy
    systemctl start tinyproxy
}

# debian code
krun::install::tinyproxy::debian() {
    # krun::install::tinyproxy::common
    apt-get update -y
    apt-get install -y tinyproxy
    systemctl enable tinyproxy
    systemctl start tinyproxy
}

# mac code
krun::install::tinyproxy::mac() {
    krun::install::tinyproxy::common
}

# common code
krun::install::tinyproxy::common() {
    echo 'common todo...'
}

# run main
krun::install::tinyproxy::run "$@"
