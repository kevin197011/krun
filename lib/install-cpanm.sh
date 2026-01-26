#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-cpanm.sh | bash

# vars

krun::install::cpanm::sudo() {
    [[ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]] && return 0
    command -v sudo >/dev/null 2>&1 && echo "sudo"
}

# run code
krun::install::cpanm::run() {
    # default debian platform
    platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::cpanm::centos() {
    sudo="$(krun::install::cpanm::sudo)"
    command -v dnf >/dev/null 2>&1 && $sudo dnf -y install perl-App-cpanminus && return
    $sudo yum -y install perl-App-cpanminus
}

# debian code
krun::install::cpanm::debian() {
    sudo="$(krun::install::cpanm::sudo)"
    $sudo apt-get update -qq || true
    $sudo apt-get install -y cpanminus
}

# mac code
krun::install::cpanm::mac() {
    brew install cpanminus
}

# run main
krun::install::cpanm::run "$@"

