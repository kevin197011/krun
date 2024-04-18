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
krun::install::aliyun-cli::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::aliyun-cli::centos() {
    krun::install::aliyun-cli::common
}

# debian code
krun::install::aliyun-cli::debian() {
    krun::install::aliyun-cli::common
}

# mac code
krun::install::aliyun-cli::mac() {
    krun::install::aliyun-cli::common
}

# common code
krun::install::aliyun-cli::common() {
    curl -fsSL https://raw.githubusercontent.com/aliyun/aliyun-cli/HEAD/install.sh | bash
}

# run main
krun::install::aliyun-cli::run "$@"
