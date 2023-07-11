#!/usr/bin/env bash

# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::config::locales::run() {
  # default debian platform
  platform='debian'

  command -v yum >/dev/null && platform='centos'
  eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::locales::centos() {
  echo 'centos todo...'
}

# debian code
krun::config::locales::debian() {
  apt clean -y
  apt update -y
  apt install locales -y
  grep -q 'LC_ALL=en_US.UTF-8' /etc/environment || echo "LC_ALL=en_US.UTF-8" >>/etc/environment
  grep -q 'en_US.UTF-8 UTF-8' /etc/locale.gen || echo "en_US.UTF-8 UTF-8" >>/etc/locale.gen
  echo "LANG=en_US.UTF-8" >/etc/locale.conf
  locale-gen en_US.UTF-8
  export LC_ALL="en_US.UTF-8"
  dpkg-reconfigure locales
}

# common code
krun::config::locales::common() {
  echo 'common todo...'
}

# run main
krun::config::locales::run "$@"
