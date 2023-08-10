#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# install specify version golang
# export golang_version=1.20

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::golang::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::golang::centos() {
    krun::install::golang::common
}

# debian code
krun::install::golang::debian() {
    krun::install::golang::common
}

# mac code
krun::install::golang::mac() {
    krun::insta#ll::golang::common
}

# common code
krun::install::golang::common() {
    default_version='1.20'
    version=${golang_version:-$default_version}
    asdf plugin-add golang https://github.com/kennyp/asdf-golang.git
    asdf install golang $version
    asdf global golang $version
    go version
}

# run main
krun::install::golang::run "$@"
