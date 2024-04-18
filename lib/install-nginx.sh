#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::nginx::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::nginx::centos() {
    sudo yum-config-manager --save --setopt=openresty.baseurl=https://openresty.org/package/centos/7/x86_64/
    sudo yum install openresty -y
    krun::install::nginx::common
}

# debian code
krun::install::nginx::debian() {
    wget -qO - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
    sudo apt-get -y install software-properties-common -y
    sudo add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main"
    sudo apt-get update
    sudo apt-get install openresty -y
    krun::install::nginx::common
}

# mac code
krun::install::nginx::mac() {
    brew install openresty/brew/openresty
    krun::install::nginx::common
}

# common code
krun::install::nginx::common() {
    nginx -v
}

# run main
krun::install::nginx::run "$@"
