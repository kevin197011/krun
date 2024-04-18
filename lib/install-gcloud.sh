#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# vars

# run code
krun::install::gcloud::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::gcloud::centos() {
    krun::install::gcloud::common
}

# debian code
krun::install::gcloud::debian() {
    apt-get update -y
    apt-get install apt-transport-https ca-certificates gnupg curl -y
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    sudo apt-get update -y && sudo apt-get install google-cloud-cli -y
    krun::install::gcloud::common
}

# mac code
krun::install::gcloud::mac() {
    krun::install::gcloud::common
}

# common code
krun::install::gcloud::common() {
    echo 'common todo...'
}

# run main
krun::install::gcloud::run "$@"
