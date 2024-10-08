#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-nerd-fonts.sh | bash

# vars

# run code
krun::install::nerd_fonts::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::nnerd_fontsginx::centos() {
    yum install git -y
    krun::install::nerd_fonts::common
}

# debian code
krun::install::nerd_fonts::debian() {
    apt-get install git -y
    krun::install::nerd_fonts::common
}

# mac code
krun::install::nerd_fonts::mac() {
    # krun::install::nerd_fonts::common
    echo 'skip...'
}

# common code
krun::install::nerd_fonts::common() {
    git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git /tmp/nerd-fonts
    /tmp/nerd-fonts/install.sh FiraCode
    rm -rf /tmp/nerd-fonts/
}

# run main
krun::install::nerd_fonts::run "$@"
