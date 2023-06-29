#!/usr/bin/env bash

# Copyright (c) 2022 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::python3::run() {
  # default debian platform
  platform='debian'

  command -v yum >/dev/null && platform='centos'
  eval "${FUNCNAME/base/${platform}}"
}

# centos code
krun::install::python3::centos() {
  echo 'centos todo...'
}

# debian code
krun::install::python3::debian() {
  apt update -y
  apt install -y build-essential zlib1g-dev libncurses5-dev \
    libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev \
    libsqlite3-dev wget libbz2-dev
  apt install -y python3
  apt install -y python3-pip
  python3 -V
  pip3 -V
}

# run main
krun::install::python3::run "$@"
