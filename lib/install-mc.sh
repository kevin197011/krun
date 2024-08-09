#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-mc.sh | bash

# vars

# run code
krun::install::mc::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::mc::centos() {
    krun::install::mc::common
}

# debian code
krun::install::mc::debian() {
    krun::install::mc::common
}

# mac code
krun::install::mc::mac() {
    # krun::install::mc::common
    echo 'mac skip...'
}

# common code
krun::install::mc::common() {
    curl https://dl.min.io/client/mc/release/linux-amd64/mc \
        --create-dirs \
        -o /usr/bin/mc

    curl -fssL https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/bin/mc
    chmod +x /usr/bin/mc

    mc -v

    # Set minio token key
    # mc alias set myminio http://vcs.slleisure.com:9000 xxxxx xxxxxxxxxxxxxxxxxxxxxxx

    # # sync local dir to minio bucket
    # mc mirror /local/test myminio/bucket

    # # sync minio bucket to local dir
    # mc mirror myminio/bucket /local/test
}

# run main
krun::install::mc::run "$@"
