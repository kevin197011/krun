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
krun::check::ip::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::check::ip::centos() {
    yum install jq -y
    yum install curl -y
    krun::check::ip::common
}

# debian code
krun::check::ip::debian() {
    apt-get update
    apt-get install jq -y
    apt-get install curl -y
    krun::check::ip::common
}

# mac code
krun::check::ip::mac() {
    brew install jq
    brew install curl
    krun::check::ip::common
}

# common code
krun::check::ip::common() {
    curl -s http://ip-api.com/json | jq
}

# run main
krun::check::ip::run "$@"
