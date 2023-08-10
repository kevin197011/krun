#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# vars

# run code
krun::update::vagrant_box::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::update::vagrant_box::centos() {
    krun::update::vagrant_box::common
}

# debian code
krun::update::vagrant_box::debian() {
    krun::update::vagrant_box::common
}

# mac code
krun::update::vagrant_box::mac() {
    krun::update::vagrant_box::common
}

# common code
krun::update::vagrant_box::common() {
    # Find all boxes which have updates
    AVAILABLE_UPDATES=$(vagrant box outdated --global | grep outdated | tr -d "*'" | cut -d ' ' -f 2)
    if [ ! ${#AVAILABLE_UPDATES[@]} -eq 0 ]; then
        for box in $AVAILABLE_UPDATES; do
            echo "Found an update for $box"
            # Find all current versions
            VERSIONS=$(vagrant box list | grep $box | cut -d ',' -f 2 | tr -d ' )')
            # Add latest version
            vagrant box add --clean $box
            BOX_UPDATED="TRUE"
            # Remove all old versions
            for version in $VERSIONS; do
                vagrant box remove $box -f --box-version=$version
            done
        done
        echo "All boxes are now up to date!"
    else
        echo "All boxes are already up to date!"
    fi
    vagrant box outdated --global
}

# run main
krun::update::vagrant_box::run "$@"
