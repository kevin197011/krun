#!/usr/bin/env bash

# Copyright (c) 2022 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# base code
krun::install::k9s::run() {
  # default debian platform
  platform='debian'

  command -v yum >/dev/null && platform='centos'
  eval "${FUNCNAME/base/${platform}}"
}

# centos code
krun::install::k9s::centos() {
  krun::install::k9s::common
}

# debian code
krun::install::k9s::debian() {
  krun::install::k9s::common
}

# common code
krun::install::k9s::common() {
  curl -sS https://webi.sh/k9s | sh
  echo 'export PATH="/root/.local/bin:$PATH"' >>/root/.bashrc
  echo 'source ~/.config/envman/PATH.env' >>/root/.bashrc
  bash
}

# run main
krun::install::k9s::run "$@"
