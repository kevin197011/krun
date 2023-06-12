#!/usr/bin/env bash

# Copyright (c) 2022 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# base code
krun::base::install::docker() {
    grep -q 'Debian' /etc/issue && version='debian'
    os="${version:-'centos'}"
    eval "${FUNCNAME/base/${os}}"
}

krun::install::docker::debian() {
    sudo apt-get -y remove docker docker-engine docker.io containerd runc
    sudo apt-get -y update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
        "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
        "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt-get -y update
    sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    systemctl start docker &&
    systemctl enable docker &&
    docker version &&
    docker compose version

}

krun::install::docker::centos() {
    sudo yum update -y &&
        sudo yum remove -y docker \
            docker-client \
            docker-client-latest \
            docker-common \
            docker-latest \
            docker-latest-logrotate \
            docker-logrotate \
            docker-engine &&
        sudo yum install -y yum-utils epel-release &&
        sudo yum-config-manager \
            --add-repo \
            'https://download.docker.com/linux/centos/docker-ce.repo' &&
        sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    systemctl start docker &&
        systemctl enable docker &&
        docker version &&
        docker compose version

}

# run main
krun::install::docker::base "$@"
