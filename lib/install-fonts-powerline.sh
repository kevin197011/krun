#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-fonts-powerline.sh | bash

# vars

# run code
krun::install::fonts-powerline::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::fonts-powerline::centos() {
    krun::install::fonts-powerline::common
}

# debian code
krun::install::fonts-powerline::debian() {
    krun::install::fonts-powerline::common
}

# mac code
krun::install::fonts-powerline::mac() {
    # krun::install::fonts-powerline::common
}

# common code
krun::install::fonts-powerline::common() {
    git clone https://github.com/powerline/fonts.git /tmp/fonts &&
        cd /tmp/fonts && ./install.sh &&
        rm -rf /tmp/fonts
}

# run main
krun::install::fonts-powerline::run "$@"
