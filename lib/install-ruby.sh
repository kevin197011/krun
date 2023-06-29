#!/usr/bin/env bash

# Copyright (c) 2022 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::ruby::run() {
  # default debian platform
  platform='debian'

  command -v yum >/dev/null && platform='centos'
  eval "${FUNCNAME/base/${platform}}"
}

# centos code
krun::install::ruby::centos() {
  yum install -y git gcc gcc-c++ make
  yum install -y openssl-devel zlib-devel
  krun::install::ruby::common
}

# debian code
krun::install::ruby::debian() {
  apt install -y git-all build-essential manpages-dev make
  apt install -y libssl-dev zlib1g zlib1g-dev
  krun::install::ruby::common
}

# common code
krun::install::ruby::common() {
  rm -rf /opt/.asdf
  git clone https://github.com/asdf-vm/asdf.git /opt/.asdf --branch master
  echo 'source /opt/.asdf/asdf.sh' >/etc/profile.d/asdf.sh
  echo 'source /opt/.asdf/completions/asdf.bash' >>/etc/profile.d/asdf.sh
  source /etc/profile
  asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git
  asdf install ruby 3.1.2
  asdf global ruby 3.1.2
  ruby -v
}

# run main
krun::install::ruby::run "$@"
