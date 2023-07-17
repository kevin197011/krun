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
  apt-get purge -y locales
  apt-get purge -y language-pack-en
  apt-get install -y locales
  apt-get install -y language-pack-en
  locale-gen en_us.utf-8
  localedef -i en_US -f UTF-8 en_US.UTF-8
}

# common code
krun::config::locales::common() {
  echo 'common todo...'
}

# run main
krun::config::locales::run "$@"
