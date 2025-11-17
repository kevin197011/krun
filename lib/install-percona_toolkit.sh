#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-percona_toolkit.sh | bash

# vars

# run code
krun::install::percona_toolkit::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::percona_toolkit::centos() {
    yum install -y perl-DBI perl-DBD-MySQL perl-Time-HiRes perl-IO-Socket-SSL
    yum install -y https://downloads.percona.com/downloads/percona-toolkit/3.5.4/binary/redhat/7/x86_64/percona-toolkit-3.5.4-2.el7.x86_64.rpm
    krun::install::percona_toolkit::common
}

# debian code
krun::install::percona_toolkit::debian() {
    apt install percona-toolkit
    krun::install::percona_toolkit::common
}

# mac code
krun::install::percona_toolkit::mac() {
    krun::install::percona_toolkit::common
}

# common code
krun::install::percona_toolkit::common() {
    echo "Percona Toolkit installation completed"
}

# run main
krun::install::percona_toolkit::run "$@"
