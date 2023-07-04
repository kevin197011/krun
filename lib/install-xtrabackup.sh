#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::xtrabackup::run() {
  # default debian platform
  platform='debian'
  # command -v apt >/dev/null && platform='debian'
  command -v yum >/dev/null && platform='centos'
  command -v brew >/dev/null && platform='mac'
  eval "${FUNCNAME/run/${platform}}"
}

# centos code
krun::install::xtrabackup::centos() {
  yum install -y perl-Digest-MD5
  yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
  percona-release enable-only tools release
  yum install -y https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-2.4.4/binary/redhat/7/x86_64/percona-xtrabackup-24-2.4.4-1.el7.x86_64.rpm
  yum install -y lz4
  krun::install::xtrabackup::common
}

# debian code
krun::install::xtrabackup::debian() {
  echo 'debian todo...'
  krun::install::xtrabackup::common
}

# mac code
krun::install::xtrabackup::mac() {
  echo 'mac todo...'
}

# common code
krun::install::xtrabackup::common() {
  echo 'common todo...'
}

# run main
krun::install::xtrabackup::run "$@"
