#!/usr/bin/env bash

# Copyright (c) 2022 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# install kssh to mac

set -o errexit
set -o nounset
set -o pipefail

# base code
krun::install::kssh::base() {
  # version=$(grep -q 'Debian' /etc/issue && echo -n 'debian' || echo -n 'centos')
  # eval "${FUNCNAME/base/${version}}"
  krun::install::kssh::mac
}

# # centos code
# krun::install::kssh::centos() {
#   echo 'TODO...'
# }

# # debian code
# krun::install::kssh::debian() {
#   echo 'TODO...'
# }

krun::install::kssh::mac() {
  git clone https://github.com/kevin197011/kssh.git ~/.kssh
  cd .kssh && bundle install
  grep -q 'export PATH="$PATH:~/.kssh/bin"' ~/.zshrc || echo 'export PATH="$PATH:~/.kssh/bin"' >>~/.zshrc
  zsh
}

# run main
krun::install::kssh::base "$@"
