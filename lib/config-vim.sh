#!/usr/bin/env bash

# Copyright (c) 2022 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::config::vim::run() {
  # default debian platform
  platform='debian'

  command -v yum >/dev/null && platform='centos'
  eval "${FUNCNAME/base/${platform}}"
}

# centos code
krun::config::vim::centos() {
  krun::config::vim::common
}

# debian code
krun::config::vim::debian() {
  krun::config::vim::common
}

# common code
krun::config::vim::common() {
  grep -q 'set paste' /etc/vimrc || echo 'set paste' >>/etc/vimrc
}

# run main
krun::config::vim::run "$@"
