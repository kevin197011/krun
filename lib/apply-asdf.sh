#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/apply-asdf.sh | bash

# vars

# run code
krun::apply::asdf::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::apply::asdf::centos() {
    krun::apply::asdf::common
}

# debian code
krun::apply::asdf::debian() {
    krun::apply::asdf::common
}

# mac code
krun::apply::asdf::mac() {
    krun::apply::asdf::common
}

# common code
krun::apply::asdf::common() {
    command -v asdf >/dev/null || krun install-asdf.sh

    printf "app name:"
    read name
    asdf plugin add ${name} || true
    asdf list all ${name}
    printf "${name} version:"
    read version
    asdf install ${name} ${version}
    asdf global ${name} ${version}
}

# run main
krun::apply::asdf::run "$@"
