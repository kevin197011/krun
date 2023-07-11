#!/usr/bin/env bash

# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::docker::run() {
  # default debian platform
  platform='debian'
  # command -v apt >/dev/null && platform='debian'
  command -v yum >/dev/null && platform='centos'
  command -v brew >/dev/null && platform='mac'
  eval "${FUNCNAME/::run/::${platform}}"
}

krun::install::docker::debian() {
  apt-get -y remove docker docker-engine docker.io containerd runc
  apt-get -y update
  apt-get install -y ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
        "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |
    tee /etc/apt/sources.list.d/docker.list >/dev/null
  apt-get -y update
  apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  systemctl start docker &&
    systemctl enable docker &&
    krun::install::docker::common
}

krun::install::docker::centos() {
  yum update -y
  yum remove -y docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine
  yum install -y yum-utils epel-release
  yum-config-manager \
    --add-repo \
    'https://download.docker.com/linux/centos/docker-ce.repo'
  yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  systemctl start docker &&
    systemctl enable docker &&
    krun::install::docker::common
}

# mac code
krun::install::docker::mac() {
  brew install docker
  krun::install::docker::common
}

# common code
krun::install::docker::common() {
  docker version
  docker compose version
}

# run main
krun::install::docker::run "$@"
