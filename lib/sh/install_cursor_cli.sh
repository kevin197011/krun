#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_cursor_cli.sh | bash

# vars

# run code
krun::install::cursor_cli::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::cursor_cli::centos() {
    krun::install::cursor_cli::common
}

# debian code
krun::install::cursor_cli::debian() {
    krun::install::cursor_cli::common
}

# mac code
krun::install::cursor_cli::mac() {
    krun::install::cursor_cli::common
}

# common code
krun::install::cursor_cli::common() {
    echo "Installing Cursor CLI on ${platform}"
    curl -fsSL https://cursor.com/install | bash
}

# run main
krun::install::cursor_cli::run "$@"
