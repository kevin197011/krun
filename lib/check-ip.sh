#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/check-ip.sh | bash

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
    yum install jq -y >/dev/null
    yum install curl -y >/dev/null
    krun::check::ip::common
}

# debian code
krun::check::ip::debian() {
    apt-get update >/dev/null
    apt-get install jq -y >/dev/null
    apt-get install curl -y >/dev/null
    krun::check::ip::common
}

# mac code
krun::check::ip::mac() {
    brew install jq >/dev/null
    brew install curl >/dev/null
    krun::check::ip::common
}

# common code
krun::check::ip::common() {
    curl -s http://ip-api.com/json | jq
}

# run main
krun::check::ip::run "$@"
