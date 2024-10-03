#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-kind.sh | bash

# vars

# run code
krun::install::kind::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::kind::centos() {
    krun::install::kind::common
}

# debian code
krun::install::kind::debian() {
    krun::install::kind::common
}

# mac code
krun::install::kind::mac() {
    # krun::install::kind::common
    brew install kind
}

# common code
krun::install::kind::common() {
    curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
    chmod +x /usr/local/bin/kind
}

# run main
krun::install::kind::run "$@"
