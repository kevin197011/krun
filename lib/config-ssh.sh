#!/usr/bin/env bash

# Copyright (c) 2022 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# base code
krun::base::config::ssh() {
  grep -q 'Debian' /etc/issue && version='debian'
  os_version="${version:-'centos'}"
  eval "${FUNCNAME/base/${os_version}}"
}

# centos code
krun::centos::config::ssh() {
  perl -i -pe 's/(\s*)(#*)(\s*)PasswordAuthentication(.*)/PasswordAuthentication no/g' /etc/ssh/sshd_config
  perl -i -pe 's/(\s*)(#*)(\s*)PermitRootLogin(.*)/PermitRootLogin no/g' /etc/ssh/sshd_config
  systemctl restart sshd
}

# debian code
krun::debian::config::ssh() {
  perl -i -pe 's/(\s*)(#*)(\s*)PasswordAuthentication(.*)/PasswordAuthentication no/g' /etc/ssh/sshd_config
  perl -i -pe 's/(\s*)(#*)(\s*)PermitRootLogin(.*)/PermitRootLogin no/g' /etc/ssh/sshd_config
  systemctl restart sshd
}

# run main
# exec krun::base::config::ssh "$@"
krun::base::config::ssh "$@"
