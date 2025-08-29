#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-disk-data.sh | bash

# vars
data_disk="${data_disk:-/dev/sda}"
mount_point="${mount_point:-/data}"

# run code
krun::config::disk-data::run() {
    # default debian platform
    platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::disk-data::centos() {
    krun::config::disk-data::common
}

# debian code
krun::config::disk-data::debian() {
    krun::config::disk-data::common
}

# mac code
krun::config::disk-data::mac() {
    echo 'mac todo...'
    # krun::config::disk-data::common
}

# common code
krun::config::disk-data::common() {
    # safety check
    if [[ "$data_disk" == "/" ]] || [[ "$data_disk" == "/dev/sda1" ]]; then
        echo "❌ Dangerous operation: System disk detected, exiting!"
        exit 1
    fi

    # check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo "❌ This script must be run as root or with sudo"
        exit 1
    fi

    # create mount point
    echo "Creating mount point: $mount_point"
    mkdir -p "$mount_point"

    # format disk if not formatted
    if ! blkid "$data_disk" >/dev/null 2>&1; then
        echo "Formatting $data_disk as xfs..."
        mkfs.xfs -f "$data_disk"
    fi

    # get UUID
    uuid=$(blkid -s UUID -o value "$data_disk")

    # update fstab safely
    if ! grep -q "$uuid" /etc/fstab; then
        echo "Writing to /etc/fstab..."
        echo "UUID=$uuid $mount_point xfs defaults 0 0" >>/etc/fstab
    fi

    # mount
    if ! mountpoint -q "$mount_point"; then
        echo "Mounting $mount_point..."
        mount "$mount_point"
    fi

    # create record directory
    mkdir -p "$mount_point/record"

    echo "✅ Data disk $data_disk mounted to $mount_point, UUID=$uuid"
}

# run main
krun::config::disk-data::run "$@"
