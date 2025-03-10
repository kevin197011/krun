#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-asdf.sh | bash

# vars

# run code
krun::install::asdf::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::asdf::centos() {
    yum install -y gnupg2 curl gawk
    krun::install::asdf::common
}

# debian code
krun::install::asdf::debian() {
    apt-get install -y dirmngr gpg curl gawk
    krun::install::asdf::common
}

# mac code
krun::install::asdf::mac() {
    command -v asdf >/dev/null && echo "asdf is installed, exit!" && exit 0
    brew install gpg gawk
    brew install asdf
}

# common code
krun::install::asdf::common() {
    command -v asdf >/dev/null && exit 0
    rm -rf ${HOME}/.asdf
    git clone https://github.com/asdf-vm/asdf.git ${HOME}/.asdf --branch master
    grep -q 'source ${HOME}/.asdf/asdf.sh' ${HOME}/.bashrc || echo 'source ${HOME}/.asdf/asdf.sh' >>${HOME}/.bashrc
    # export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
    # grep -q 'source ${HOME}/.asdf/completions/asdf.bash' ${HOME}/.bashrc || echo 'source ${HOME}/.asdf/completions/asdf.bash' >>${HOME}/.bashrc
    exec bash
}

# run main
krun::install::asdf::run "$@"
