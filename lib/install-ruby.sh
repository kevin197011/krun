#!/usr/bin/env bash

# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-ruby.sh | bash

# vars

# run code
krun::install::ruby::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::ruby::centos() {
    yum install -y git gcc gcc-c++ make
    yum install -y openssl-devel zlib-devel
    krun::install::ruby::common
}

# debian code
krun::install::ruby::debian() {
    apt install -y git-all build-essential manpages-dev make
    apt install -y libssl-dev zlib1g zlib1g-dev
    krun::install::ruby::common
}

# mac code
krun::install::ruby::mac() {
    brew install openssl zlib
    krun::install::ruby::common
}

# common code
krun::install::ruby::common() {
    local version=${ruby_version:-3.0.0}
    # command -v asdf >/dev/null || krun install-asdf.sh
    command -v asdf >/dev/null || (curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-asdf.sh | bash)
    source  ${HOME}/.bashrc
    asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git || true
    asdf install ruby ${version}
    asdf global ruby ${version}
    ruby -v
}

# run main
krun::install::ruby::run "$@"
