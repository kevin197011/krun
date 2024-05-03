#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# https://www.aapanel.com/new/download.html#install

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::aapanel::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::aapanel::centos() {
    krun::install::aapanel::common
    yum install -y curl
    curl -fsSL http://www.aapanel.com/script/install_6.0_en.sh | bash
}

# debian code
krun::install::aapanel::debian() {
    krun::install::aapanel::common
    apt install -y curl
    curl -fsSL http://www.aapanel.com/script/install-ubuntu_6.0_en.sh | bash
}

# mac code
krun::install::aapanel::mac() {
    krun::install::aapanel::common
    echo "mac skip install aapanel..."
}

# common code
krun::install::aapanel::common() {
    echo 'install aapanel...'
}

# run main
krun::install::aapanel::run "$@"
