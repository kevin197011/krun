#!/usr/bin/env bash

# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::nginx::run() {
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
krun::install::nginx::run "$@"
