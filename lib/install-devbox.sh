#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-devbox.sh | bash

# vars

# run code
krun::install::devbox::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::devbox::centos() {
    krun::install::devbox::common
}

# debian code
krun::install::devbox::debian() {
    krun::install::devbox::common
}

# mac code
krun::install::devbox::mac() {
    krun::install::devbox::common
}

# common code
krun::install::devbox::common() {
    echo "Installing devbox on ${platform}"
    curl -fsSL https://get.jetify.com/devbox | bash
}

# run main
krun::install::devbox::run "$@"
