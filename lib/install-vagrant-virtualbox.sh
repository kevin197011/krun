#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# create vms
# mkdir -p /tmp/node01 && cd /tmp/node01 && \
# vagrant init centos/7 && vagrant up
# vagrant ssh

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::vagrant-virtualbox::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::vagrant-virtualbox::centos() {
    # virtualbox
    yum install -y epel-release wget
    yum install -y gcc dkms make qt libgomp patch
    yum install -y kernel-headers kernel-devel binutils glibc-headers glibc-devel fontforge
    wget http://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo -O /etc/yum.repos.d/virtualbox.repo
    yum install -y VirtualBox-5.2

    # vagrant
    yum install -y https://releases.hashicorp.com/vagrant/2.2.19/vagrant_2.2.19_x86_64.rpm
    vagrant --version

    krun::install::vagrant-virtualbox::common
}

# debian code
krun::install::vagrant-virtualbox::debian() {
    echo 'debian todo...'
    apt install virtualbox
    wget https://releases.hashicorp.com/vagrant/2.3.7/vagrant_2.3.7-1_amd64.deb -O /tmp/vagrant.deb
    apt install /tmp/vagrant.deb
    rm -rf /tmp/vagrant.deb
    krun::install::vagrant-virtualbox::common
}

# mac code
krun::install::vagrant-virtualbox::mac() {
    brew cask install virtualbox
    brew cask install vagrant
    brew cask install vagrant-manager
    krun::install::vagrant-virtualbox::common
}

# common code
krun::install::vagrant-virtualbox::common() {
    # version
    vagrant --version

    # images
    vagrant box add centos/7
    vagrant box add ubuntu/trusty64
    vagrant box add debian/bullseye64
}

# run main
krun::install::vagrant-virtualbox::run "$@"
