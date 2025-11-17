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

    # Remove existing .cursor directory
    rm -rf .cursor

    # Clone cursor repository
    echo "Cloning cursor repository..."
    git clone git@github.com:kevin197011/cursor.git .cursor

    # Handle Rakefile
    if [[ ! -f Rakefile ]]; then
        echo "Moving Rakefile from .cursor to current directory..."
        mv .cursor/Rakefile .
    else
        echo "Rakefile already exists, removing .cursor/Rakefile..."
        rm -rf .cursor/Rakefile
    fi

    # Move push.rb
    echo "Moving push.rb from .cursor to current directory..."
    mv .cursor/push.rb .

    # Move .rubocop.yml
    echo "Moving .rubocop.yml from .cursor to current directory..."
    mv .cursor/.rubocop.yml .

    # Remove .git directory from .cursor
    echo "Removing .git directory from .cursor..."
    rm -rf .cursor/.git

    # Update .gitignore
    if ! grep -q '\.cursor' .gitignore 2>/dev/null; then
        echo "Adding .cursor to .gitignore..."
        printf '\n.cursor\n' >>.gitignore
    else
        echo ".cursor already in .gitignore"
    fi

    echo "✅ Cursor configuration completed successfully"
}

# run main
krun::config::cursor::run "$@"
