#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-elasticsearch.sh | bash

# vars

# run code
krun::config::elasticsearch::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::elasticsearch::centos() {
    yum install -y curl
    krun::config::elasticsearch::common
}

# debian code
krun::config::elasticsearch::debian() {
    apt install -y curl
    krun::config::elasticsearch::common
}

# mac code
krun::config::elasticsearch::mac() {
    brew install curl
    krun::config::elasticsearch::common
}

# common code
krun::config::elasticsearch::common() {
    # resolve elasticsearch single node yellow status issues
    curl -X PUT "127.0.0.1:9200/_settings" -H 'Content-Type: application/json' -d '{"number_of_replicas": 0}'
    curl -X PUT "127.0.0.1:9200/_template/*" -H 'Content-Type: application/json' \
        -d '{"template": "*", "settings": {"number_of_shards": 1, "number_of_replicas": 0}}'
}

# run main
krun::config::elasticsearch::run "$@"
