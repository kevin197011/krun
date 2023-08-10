#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::python3::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::python3::centos() {
    echo 'centos todo...'
    krun::install::python3::common
}

# debian code
krun::install::python3::debian() {
    echo 'debian todo...'
    krun::install::python3::common
}

# mac code
krun::install::python3::mac() {
    echo 'mac todo...'
    krun::install::python3::common
}

# common code
krun::install::python3::common() {
    echo 'common todo...'
}

# run main
krun::install::python3::run "$@"
