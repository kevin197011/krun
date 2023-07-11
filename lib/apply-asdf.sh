#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# vars
app_name=${1:-''}

# run code
krun::apply::asdf::run() {
  # default platform
  platform='debian'
  # command -v apt >/dev/null && platform='debian'
  command -v yum >/dev/null && platform='centos'
  command -v brew >/dev/null && platform='mac'
  eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::apply::asdf::centos() {
  krun::apply::asdf::common
}

# debian code
krun::apply::asdf::debian() {
  krun::apply::asdf::common
}

# mac code
krun::apply::asdf::mac() {
  krun::apply::asdf::common
}

# common code
krun::apply::asdf::common() {
  # prepare
  krun install-asdf.sh && bash

  # action
  [[ -z ${app_name} ]] && echo "app_name is empty, exit!" && exit 1
  asdf plugin add ${app_name}
  asdf list all ${app_name}
  printf "${app_name} version:"
  read version
  asdf install ${app_name} ${version}
  asdf global ${app_name} ${version}
}

# run main
krun::apply::asdf::run "$@"
