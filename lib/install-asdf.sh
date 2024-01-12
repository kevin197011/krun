#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

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
    krun::install::asdf::common
}

# debian code
krun::install::asdf::debian() {
    krun::install::asdf::common
}

# mac code
krun::install::asdf::mac() {
    command -v asdf >/dev/null && echo "asdf is installed, exit!" && exit 0
    brew install asdf
}

# common code
krun::install::asdf::common() {
    command -v asdf >/dev/null && exit 0
    rm -rf ${HOME}/.asdf
    git clone https://github.com/asdf-vm/asdf.git ${HOME}/.asdf --branch master
    grep -q 'source ${HOME}/.asdf/asdf.sh' ${HOME}/.bashrc || echo 'source ${HOME}/.asdf/asdf.sh' >>${HOME}/.bashrc
    grep -q 'source ${HOME}/.asdf/completions/asdf.bash' ${HOME}/.bashrc || echo 'source ${HOME}/.asdf/completions/asdf.bash' >>${HOME}/.bashrc
    source ${HOME}/.bashrc
}

# run main
krun::install::asdf::run "$@"
