#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::puppet_bolt::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::puppet_bolt::centos() {
    krun::install::puppet_bolt::common
}

# debian code
krun::install::puppet_bolt::debian() {
    wget https://apt.puppet.com/puppet-tools-release-jammy.deb
    sudo dpkg -i puppet-tools-release-jammy.deb
    rm -rf puppet-tools-release-jammy.deb
    sudo apt-get update -y
    sudo apt-get install puppet-bolt -y
    krun::install::puppet_bolt::common
}

# mac code
krun::install::puppet_bolt::mac() {
    brew tap puppetlabs/puppet
    brew install --cask puppet-bolt
    brew install --cask puppetlabs/puppet/pdk
    krun::install::puppet_bolt::common
}

# common code
krun::install::puppet_bolt::common() {
    bolt --version
}

# run main
krun::install::puppet_bolt::run "$@"
