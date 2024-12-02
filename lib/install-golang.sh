#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-golang.sh | bash

# vars

# run code
krun::install::golang::run() {
    # default platform
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
    krun::install::golang::common
}

# common code
krun::install::golang::common() {
    # https://go.dev/dl/?mode=json
    default_version='latest'
    version=${golang_version:-$default_version}
    asdf plugin-add golang https://github.com/kennyp/asdf-golang.git
    asdf install golang $version
    asdf global golang $version
    go version
}

# run main
krun::install::golang::run "$@"
