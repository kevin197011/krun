#!/usr/bin/env bash

# Copyright (c) 2022 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::openjdk8::run() {
  # default debian platform
  platform='debian'

  command -v yum >/dev/null && platform='centos'
  eval "${FUNCNAME/base/${platform}}"
}

# centos code
krun::install::openjdk8::centos() {
  yum install java-1.8.0-openjdk -y
  java -version
}

# debian code
krun::install::openjdk8::debian() {
  echo 'debian todo...'
}

# run main
krun::install::openjdk8::run "$@"
