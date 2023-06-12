#!/usr/bin/env bash

# Copyright (c) 2022 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# base code
krun::install::k9s::base() {
  version=$(grep -q 'Debian' /etc/issue && echo -n 'debian' || echo -n 'centos')
  eval "${FUNCNAME/base/${version}}"
}

# centos code
krun::install::k9s::centos() {
  # grep -q -i 'centos' /etc/os-release || echo "System unsupported, exit!"; exit 1
  curl -sS https://webi.sh/k9s | sh
  echo 'export PATH="/root/.local/bin:$PATH"' >>/root/.bashrc
  echo 'source ~/.config/envman/PATH.env' >>/root/.bashrc
}

# debian code
krun::install::k9s::debian() {
  echo 'TODO...'
}

# run main
krun::install::k9s::base "$@"
