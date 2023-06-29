#!/usr/bin/env bash

# Copyright (c) 2022 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::ansible::run() {
  # default debian platform
  platform='debian'

  command -v yum >/dev/null && platform='centos'
  eval "${FUNCNAME/base/${platform}}"
}

# centos code
krun::install::ansible::centos() {
  echo 'centos todo...'
}

# debian code
krun::install::ansible::debian() {
  echo 'debian todo...'
}

# common code
krun::install::ansible::common() {
  echo 'common todo...'
}

# run main
krun::install::ansible::run "$@"
