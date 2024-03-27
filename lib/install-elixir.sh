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
krun::install::elixir::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::elixir::centos() {
    krun::install::elixir::common
}

# debian code
krun::install::elixir::debian() {
    krun::install::elixir::common
}

# mac code
krun::install::elixir::mac() {
    krun::install::elixir::common
}

# common code
krun::install::elixir::common() {
    echo 'common todo...'
}

# run main
krun::install::elixir::run "$@"
