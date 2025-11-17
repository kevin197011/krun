#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-aliyun-cli.sh | bash

# vars

# run code
krun::install::aliyun-cli::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
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
