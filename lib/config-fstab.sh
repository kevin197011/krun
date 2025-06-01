#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-fstab.sh | bash

# vars

# run code
krun::config::fstab::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::fstab::centos() {
    echo "Configuring fstab on CentOS/RHEL..."
    krun::config::fstab::common
}

# debian code
krun::config::fstab::debian() {
    echo "Configuring fstab on Debian/Ubuntu..."
    krun::config::fstab::common
}

# mac code
krun::config::fstab::mac() {
    echo "macOS does not use /etc/fstab in the traditional way"
    echo "Use Disk Utility or diskutil for mount configuration"
    return 0
}

# common code
krun::config::fstab::common() {
    echo "Configuring /etc/fstab..."

    # Backup current fstab
    if [[ -f /etc/fstab ]]; then
        cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d-%H%M%S)
        echo "✓ Backed up current fstab"
    fi

    # Show current fstab
    echo ""
    echo "Current /etc/fstab contents:"
    echo "================================"
    cat /etc/fstab 2>/dev/null || echo "No fstab file found"
    echo "================================"

    # Show mounted filesystems
    echo ""
    echo "Currently mounted filesystems:"
    echo "================================"
    df -h
    echo "================================"

    # Show available block devices
    echo ""
    echo "Available block devices:"
    echo "================================"
    if command -v lsblk >/dev/null 2>&1; then
        lsblk
    else
        fdisk -l 2>/dev/null | grep -E '^Disk /dev'
    fi
    echo "================================"

    echo ""
    echo "⚠ IMPORTANT: Modifying /etc/fstab can make your system unbootable!"
    echo "Always test mount points manually before adding to fstab:"
    echo ""
    echo "Example fstab entry:"
    echo "/dev/sdb1 /mnt/data ext4 defaults,noatime 0 2"
    echo ""
    echo "Common mount options:"
    echo "  defaults    - rw,suid,dev,exec,auto,nouser,async"
    echo "  noatime     - Don't update access times (performance)"
    echo "  ro          - Read-only"
    echo "  rw          - Read-write"
    echo "  noexec      - Don't allow execution"
    echo "  nosuid      - Don't allow suid"
    echo "  nodev       - Don't allow device files"
    echo ""
    echo "Testing commands:"
    echo "  mount -a                    - Mount all fstab entries"
    echo "  mount /mnt/point           - Mount specific point"
    echo "  umount /mnt/point          - Unmount"
    echo "  findmnt                    - Show mount tree"
    echo ""
    echo "fstab configuration guidance provided."
}

# run main
krun::config::fstab::run "$@"
