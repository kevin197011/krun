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
krun::install::redis::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::redis::centos() {
    krun::install::redis::common
}

# debian code
krun::install::redis::debian() {
    krun::install::redis::common
    curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

    sudo apt-get update
    sudo apt-get install redis
    systemctl start redis-server
    systemctl enable redis-server
    systemctl status redis-server
}

# mac code
krun::install::redis::mac() {
    krun::install::redis::common
}

# common code
krun::install::redis::common() {
    echo "${FUNCNAME}"
}

# run main
krun::install::redis::run "$@"
