#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-lsyncd.sh | bash

# vars

# run code
krun::install::lsyncd::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::lsyncd::centos() {
    krun::install::lsyncd::common
}

# debian code
krun::install::lsyncd::debian() {
    krun::install::lsyncd::common
}

# mac code
krun::install::lsyncd::mac() {
    krun::install::lsyncd::common
}

# common code
krun::install::lsyncd::common() {
    echo "${FUNCNAME}"
}

# run main
krun::install::lsyncd::run "$@"
