#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-git.sh | bash

# vars

# run code
krun::config::git::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::git::centos() {
    krun::config::git::common
}

# debian code
krun::config::git::debian() {
    krun::config::git::common
}

# mac code
krun::config::git::mac() {
    krun::config::git::common
}

# common code
krun::config::git::common() {
    git config --global user.email "kevin197011@outlook.com"
    git config --global user.name "kk"
}

# run main
krun::config::git::run "$@"
