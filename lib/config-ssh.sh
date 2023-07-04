#!/usr/bin/env bash

# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::config::ssh::run() {
  # default debian platform
  platform='debian'

  command -v yum >/dev/null && platform='centos'
  eval "${FUNCNAME/run/${platform}}"
}

# centos code
krun::config::ssh::centos() {
  krun::config::ssh::common
}

# debian code
krun::config::ssh::debian() {
  krun::config::ssh::common
}

# common code
krun::config::ssh::common() {
  perl -i -pe 's/(\s*)(#*)(\s*)PasswordAuthentication(.*)/PasswordAuthentication no/g' /etc/ssh/sshd_config
  perl -i -pe 's/(\s*)(#*)(\s*)PermitRootLogin(.*)/PermitRootLogin no/g' /etc/ssh/sshd_config
  systemctl restart sshd
}

# run main
krun::config::ssh::run "$@"
