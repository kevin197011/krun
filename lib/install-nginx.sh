#!/usr/bin/env bash

# Copyright (c) 2022 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# base code
krun::install::nginx::base() {
  version=$(grep -q 'Debian' /etc/issue && echo -n 'debian' || echo -n 'centos')
  eval "${FUNCNAME/base/${version}}"
}

# centos code
krun::install::nginx::centos() {
  echo 'TODO...'
}

# debian code
krun::install::nginx::debian() {
  echo 'TODO...'
}

# run main
krun::install::nginx::base "$@"