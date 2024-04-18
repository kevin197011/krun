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
krun::install::zsh::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::zsh::centos() {
    krun::install::zsh::common
}

# debian code
krun::install::zsh::debian() {
    krun::install::zsh::common
    apt-get install zsh -y
    chsh -s /bin/zsh
    # reboot
    echo "Need reboot ubuntu!"
}

# mac code
krun::install::zsh::mac() {
    krun::install::zsh::common
}

# common code
krun::install::zsh::common() {
    echo 'common todo...'
}

# run main
krun::install::zsh::run "$@"
