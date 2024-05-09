#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::openjdk::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::openjdk::centos() {
    krun::install::openjdk::common
}

# debian code
krun::install::openjdk::debian() {
    krun::install::openjdk::common
}

# mac code
krun::install::openjdk::mac() {
    krun::install::openjdk::common
}

# common code
krun::install::openjdk::common() {
    command -v asdf >/dev/null || krun install-asdf.sh
    asdf plugin-add java
    asdf list-all java
    # asdf install java openjdk-8 not available
    asdf install java openjdk-20
    asdf global java openjdk-20
    java -version
}

# run main
krun::install::openjdk::run "$@"
