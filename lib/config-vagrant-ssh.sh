#!/usr/bin/env bash

# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::config::vagrant-ssh::run() {
  # default debian platform
  platform='debian'
  # command -v apt >/dev/null && platform='debian'
  command -v yum >/dev/null && platform='centos'
  command -v brew >/dev/null && platform='mac'
  eval "${FUNCNAME/base/${platform}}"
}

# centos code
krun::config::vagrant-ssh::centos() {
  krun::config::vagrant-ssh::common
}

# debian code
krun::config::vagrant-ssh::debian() {
  krun::config::vagrant-ssh::common
}

# mac code
krun::config::vagrant-ssh::mac() {
  krun::config::vagrant-ssh::common
}

# common code
krun::config::vagrant-ssh::common() {
  # permit root login in
  perl -i.bak -pe 's/^(\s*)PasswordAuthentication(\s*)no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  systemctl restart sshd
  echo "123456" | passwd "root" --stdin
}

# run main
krun::config::vagrant-ssh::run "$@"
