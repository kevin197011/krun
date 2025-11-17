#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-spacevim.sh | bash

# vars

# run code
krun::install::spacevim::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::spacevim::centos() {
    krun::install::spacevim::common
}

# debian code
krun::install::spacevim::debian() {
    krun::install::spacevim::common
}

# mac code
krun::install::spacevim::mac() {
    krun::install::spacevim::common
}

# common code
krun::install::spacevim::common() {
    # https://spacevim.org/quick-start-guide/
    curl -fsSL https://spacevim.org/install.sh | bash
}

# run main
krun::install::spacevim::run "$@"
