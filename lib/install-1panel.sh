#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-1panel.sh | bash

# vars

# run code
krun::install::1panel::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::1panel::centos() {
    yum install -y curl
    krun::install::1panel::common
}

# debian code
krun::install::1panel::debian() {
    apt install -y curl
    krun::install::1panel::common
}

# mac code
krun::install::1panel::mac() {
    echo "Don't install 1panel for mac."
    # krun::install::1panel::common
}

# common code
krun::install::1panel::common() {
    # https://github.com/1Panel-dev/1Panel
    curl -fsSL https://resource.fit2cloud.com/1panel/package/quick_start.sh | bash
}

# run main
krun::install::1panel::run "$@"
