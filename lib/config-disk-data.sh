#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# =========================
# vars
# =========================
data_disk="${data_disk:-/dev/sdb}"
mount_point="${mount_point:-/data}"
fs_type="${fs_type:-xfs}"

# =========================
# main entry
# =========================
krun::config::disk-data::run() {
    platform='debian'
    command -v yum >/dev/null 2>&1 && platform='centos'
    command -v dnf >/dev/null 2>&1 && platform='centos'
    command -v brew >/dev/null 2>&1 && platform='mac'

    eval "krun::config::disk-data::${platform}"
}

krun::config::disk-data::centos() {
    krun::config::disk-data::common
}

krun::config::disk-data::debian() {
    krun::config::disk-data::common
}

krun::config::disk-data::mac() {
    echo "mac not supported yet"
}

# =========================
# safety + logic
# =========================
krun::config::disk-data::common() {

    echo "👉 target disk: $data_disk"
    echo "👉 mount point: $mount_point"

    # 1. safety check
    if [[ "$data_disk" == "/" ]] || [[ "$data_disk" == "/dev/sda" ]]; then
        echo "❌ Dangerous operation: system disk detected"
        exit 1
    fi

    if [[ $EUID -ne 0 ]]; then
        echo "❌ must run as root"
        exit 1
    fi

    # 2. check disk exists
    if [[ ! -b "$data_disk" ]]; then
        echo "❌ disk not found: $data_disk"
        exit 1
    fi

    # 3. create mount point
    mkdir -p "$mount_point"

    # 4. format only if no filesystem exists
    if ! blkid "$data_disk" >/dev/null 2>&1; then
        echo "📦 formatting $data_disk as $fs_type ..."
        if [[ "$fs_type" == "xfs" ]]; then
            mkfs.xfs -f "$data_disk"
        else
            mkfs.ext4 -F "$data_disk"
        fi
    else
        echo "✅ filesystem already exists, skip mkfs"
    fi

    # 5. get UUID
    uuid=$(blkid -s UUID -o value "$data_disk")

    if [[ -z "$uuid" ]]; then
        echo "❌ cannot get UUID"
        exit 1
    fi

    # 6. fstab safe write (avoid duplicates)
    if ! grep -q "$uuid" /etc/fstab; then
        echo "📝 writing /etc/fstab ..."
        echo "UUID=$uuid $mount_point $fs_type defaults 0 0" >> /etc/fstab
    else
        echo "✅ fstab already contains entry"
    fi

    # 7. mount (FIXED PART)
    if ! mountpoint -q "$mount_point"; then
        echo "📌 mounting $data_disk -> $mount_point ..."
        mount "$data_disk" "$mount_point"
    else
        echo "✅ already mounted"
    fi

    # 8. ensure fstab mount correctness
    mount -a >/dev/null 2>&1 || true

    # 9. create dir
    mkdir -p "$mount_point/record"

    echo "🎉 DONE: $data_disk mounted at $mount_point (UUID=$uuid)"
}

# run
krun::config::disk-data::run "$@"
