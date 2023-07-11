#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::asdf::run() {
  # default debian platform
  platform='debian'
  # command -v apt >/dev/null && platform='debian'
  command -v yum >/dev/null && platform='centos'
  command -v brew >/dev/null && platform='mac'
  eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::asdf::centos() {
  krun::install::asdf::common
}

# debian code
krun::install::asdf::debian() {
  krun::install::asdf::common
}

# mac code
krun::install::asdf::mac() {
  command -v asdf >/dev/null && exit 0
  brew install asdf
}

# common code
krun::install::asdf::common() {
  command -v asdf >/dev/null && exit 0
  rm -rf /opt/.asdf
  git clone https://github.com/asdf-vm/asdf.git /opt/.asdf --branch master
  echo 'source /opt/.asdf/asdf.sh' >/etc/profile.d/asdf.sh
  echo 'source /opt/.asdf/completions/asdf.bash' >>/etc/profile.d/asdf.sh
  source /etc/profile
}

# run main
krun::install::asdf::run "$@"
