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
    # find all boxes which have updates
    available_updates=$(vagrant box outdated --global | grep outdated | tr -d "*'" | cut -d ' ' -f 2)
    if [ ! ${#available_updates[@]} -eq 0 ]; then
        for box in $available_updates; do
            echo "found an update for $box"
            # find all current versions
            versions=$(vagrant box list | grep $box | cut -d ',' -f 2 | tr -d ' )')
            # add latest version
            vagrant box add --clean $box
            box_updated="true"
            # remove all old versions
            for version in $versions; do
                vagrant box remove $box -f --box-version=$version
            done
        done
        echo "all boxes are now up to date!"
    else
        echo "all boxes are already up to date!"
    fi
    vagrant box outdated --global
}

# run main
krun::update::vagrant_box::run "$@"
