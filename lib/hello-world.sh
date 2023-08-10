#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# vars

# run code
krun::hello::world::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::hello::world::centos() {
    krun::hello::world::common
}

# debian code
krun::hello::world::debian() {
    krun::hello::world::common
}

# mac code
krun::hello::world::mac() {
    krun::hello::world::common
}

# common code
krun::hello::world::common() {
    echo 'hello world!...'
}

# run main
krun::hello::world::run "$@"
