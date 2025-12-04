#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-cursor.sh | bash

# vars

# run code
krun::config::cursor::run() {
    # default debian platform
    platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::cursor::centos() {
    krun::config::cursor::common
}

# debian code
krun::config::cursor::debian() {
    krun::config::cursor::common
}

# mac code
krun::config::cursor::mac() {
    krun::config::cursor::common
}

# common code
krun::config::cursor::common() {
    echo "Configuring cursor files..."

    rm -rf .cursor
    git clone git@github.com:kevin197011/cursor.git .cursor

    # Handle Rakefile
    if [[ ! -f Rakefile ]]; then
        mv .cursor/Rakefile .
    else
        rm -rf .cursor/Rakefile
    fi

    mv .cursor/push.rb .
    mv .cursor/.rubocop.yml .
    mv .cursor/deploy.sh .
    chmod +x ./deploy.sh
    rm -rf .cursor/.git
    grep -q '\.cursor' .gitignore 2>/dev/null || printf '\n.cursor\n' >>.gitignore

    echo "✓ Cursor configuration completed"
}

# run main
krun::config::cursor::run "$@"
