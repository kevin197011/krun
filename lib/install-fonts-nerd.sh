#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-fonts-nerd.sh | bash

# vars

# run code
krun::install::fonts-nerd::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::fonts-nerd::centos() {
    krun::install::fonts-nerd::common
}

# debian code
krun::install::fonts-nerd::debian() {
    krun::install::fonts-nerd::common
}

# mac code
krun::install::fonts-nerd::mac() {
    krun::install::fonts-nerd::common
}

# common code
krun::install::fonts-nerd::common() {
    echo "${FUNCNAME}"
    git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git /tmp/nerd-fonts &&
        /tmp/nerd-fonts/install.sh FiraCode &&
        rm -rf /tmp/nerd-fonts/
}

# run main
krun::install::fonts-nerd::run "$@"
