#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-python3.sh | bash

# vars

# run code
krun::install::python3::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::python3::centos() {
    yum install xz-devel -y
    yum install sqlite-devel -y
    yum install bzip2-devel -y
    yum install libffi-devel -y
    krun::install::python3::common
}

# debian code
krun::install::python3::debian() {
    apt-get update -y
    apt-get install liblzma-dev -y
    apt-get install libsqlite3-dev -y
    apt-get install libbz2-dev -y
    apt-get install libffi-dev -y
    krun::install::python3::common
}

# mac code
krun::install::python3::mac() {
    krun::install::python3::common
}

# common code
krun::install::python3::common() {
    version=${python_version:-3.11.0}
    asdf plugin-add python
    asdf install python ${version}
    asdf global python ${version}
    python --version
}

# run main
krun::install::python3::run "$@"
