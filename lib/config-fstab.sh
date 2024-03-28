#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# name=sdb
# mount_path=/data
# UUID=1c419d6c-5064-4a2b-953c-05b2c67edb15 /data                       xfs     defaults        0 0

# vars

# run code
krun::config::fstab::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::fstab::centos() {
    krun::config::fstab::common
}

# debian code
krun::config::fstab::debian() {
    krun::config::fstab::common
}

# mac code
krun::config::fstab::mac() {
    # krun::config::fstab::common
    echo 'mac skip...'
}

# common code
krun::config::fstab::common() {
    lsblk

    echo ''
    printf "disk name: "
    read name
    echo ''
    printf "mount path: "
    read mount_path

    (lsblk | grep -q -w ${name}) || echo "disk name error, exit!"
    exit 1

    mkdir -p ${mount_path}

    # mkfs.xfs /dev/${name}

    uuid=$(blkid | grep -w ${name} | grep -Ewo '[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}')

    grep -q ${uuid} /etc/fstab && echo 'fstab already config disk name, exit!' && exit 2
    echo ": =>"
    echo "  UUID=${uuid} ${mount_path}                       xfs     defaults        0 0"

    mount /dev/${name} ${mount_path} && echo "UUID=${uuid} ${mount_path}                       xfs     defaults        0 0" >>/etc/fstab
}

# run main
krun::config::fstab::run "$@"
