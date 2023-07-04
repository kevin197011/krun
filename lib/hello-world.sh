#!/usr/bin/env bash

# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::hello::world::run() {
  # default debian platform
  platform='debian'

  command -v yum >/dev/null && platform='centos'
  eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::hello::world::centos() {
  krun::hello::world::common
}

# debian code
krun::hello::world::debian() {
  krun::hello::world::common
}

# common code
krun::hello::world::common() {
  echo 'hello world!...'
}

# run main
krun::hello::world::run "$@"
