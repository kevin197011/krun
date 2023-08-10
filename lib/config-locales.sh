#!/usr/bin/env bash

# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::config::locales::run() {
    # default debian platform
    platform='debian'

    command -v yum >/dev/null && platform='centos'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::locales::centos() {
    echo "${FUNCNAME}"
}

# debian code
krun::config::locales::debian() {
    apt-get purge -y locales || true
    apt-get purge -y language-pack-en || true
    apt-get install -y locales
    apt-get install -y language-pack-en
    sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
    locale-gen
    localectl set-locale en_US.UTF-8
}

# common code
krun::config::locales::common() {
    echo "${FUNCNAME}"
}

# run main
krun::config::locales::run "$@"
