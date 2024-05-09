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
krun::install::maven::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::maven::centos() {
    krun::install::maven::common
}

# debian code
krun::install::maven::debian() {
    krun::install::maven::common
}

# mac code
krun::install::maven::mac() {
    krun::install::maven::common
}

# common code
krun::install::maven::common() {
    command -v asdf >/dev/null || krun install-asdf.sh
    asdf plugin-add maven # https://github.com/skotchpine/asdf-maven.git
    asdf list-all maven
    asdf install maven 3.9.6
    asdf global maven 3.9.6
    mvn --version
}

# run main
krun::install::maven::run "$@"
