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
data_disk="${data_disk:-/dev/sdb}"
mount_point="${mount_point:-/data}"
fs_type="${fs_type:-xfs}"

# run code
krun::config::disk-data::run() {
    local platform='debian'
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
    echo "mac not supported yet"
}

# common code
krun::config::disk-data::common() {
    echo "target disk: $data_disk"
    echo "mount point: $mount_point"

    if [[ "$data_disk" == "/" ]] || [[ "$data_disk" == "/dev/sda" ]]; then
        echo "✗ system disk detected, aborting"
        exit 1
    fi

    if [[ $EUID -ne 0 ]]; then
        echo "✗ must run as root"
        exit 1
    fi

    if [[ ! -b "$data_disk" ]]; then
        echo "✗ disk not found: $data_disk"
        exit 1
    fi

    mkdir -p "$mount_point"

    if ! blkid "$data_disk" >/dev/null 2>&1; then
        echo "formatting $data_disk as $fs_type"
        if [[ "$fs_type" == "xfs" ]]; then
            mkfs.xfs -f "$data_disk"
        else
            mkfs.ext4 -F "$data_disk"
        fi
        echo "✓ formatted $data_disk as $fs_type"
    else
        echo "✓ filesystem exists, skip mkfs"
    fi

    uuid=$(blkid -s UUID -o value "$data_disk")

    if [[ -z "$uuid" ]]; then
        echo "✗ cannot get UUID"
        exit 1
    fi

    if ! grep -q "$uuid" /etc/fstab; then
        echo "writing /etc/fstab"
        echo "UUID=$uuid $mount_point $fs_type defaults 0 0" >> /etc/fstab
        echo "✓ fstab updated"
    else
        echo "✓ fstab entry exists, skip"
    fi

    if ! mountpoint -q "$mount_point"; then
        echo "mounting $data_disk -> $mount_point"
        mount "$data_disk" "$mount_point"
        echo "✓ mounted at $mount_point"
    else
        echo "✓ already mounted"
    fi

    mount -a >/dev/null 2>&1 || true

    mkdir -p "$mount_point/record"

    echo "✓ done: $data_disk mounted at $mount_point (UUID=$uuid)"
}

# run main
krun::config::disk-data::run "$@"
