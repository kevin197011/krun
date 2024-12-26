#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-awscli.sh | bash

# vars

# run code
krun::install::awscli::run() {
    # default platform
    platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::awscli::centos() {
    yum remove awscli -y
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    cd /tmp
    unzip awscliv2.zip
    ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
    rm -rf /tmp/aws
    rm -rf /tmp/awscliv2.zip
    krun::install::awscli::common
}

# debian code
krun::install::awscli::debian() {
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    cd /tmp
    unzip awscliv2.zip
    ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
    rm -rf /tmp/aws
    rm -rf /tmp/awscliv2.zip
    krun::install::awscli::common
}

# mac code
krun::install::awscli::mac() {
    brew install awscli
    krun::install::awscli::common
}

# common code
krun::install::awscli::common() {
    aws --version
}

# run main
krun::install::awscli::run "$@"
