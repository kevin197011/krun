#!/usr/bin/env bash

# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/mount-disk-data.sh | bash

# vars
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

readonly DISK_DEVICE="/dev/sdb"
readonly PARTITION_DEVICE="/dev/sdb1"
readonly MOUNT_POINT="/data"
readonly FS_TYPE="xfs"

# run code
krun::mount::disk_data::run() {
    echo -e "${BLUE}💾 Mounting new disk ${DISK_DEVICE} to ${MOUNT_POINT}...${NC}"

    # detect platform
    platform='debian'
    if command -v yum >/dev/null 2>&1; then
        platform='centos'
    elif command -v dnf >/dev/null 2>&1; then
        platform='centos'
    fi

    echo -e "${GREEN}📊 Detected platform: ${platform}${NC}"

    # check if running as root
    krun::mount::disk_data::check_root

    # install required tools
    krun::mount::disk_data::install_tools

    # safety checks
    krun::mount::disk_data::safety_checks

    # backup fstab
    krun::mount::disk_data::backup_fstab

    # partition the disk
    krun::mount::disk_data::partition_disk

    # format the partition
    krun::mount::disk_data::format_partition

    # create mount point
    krun::mount::disk_data::create_mount_point

    # mount the partition
    krun::mount::disk_data::mount_partition

    # update fstab
    krun::mount::disk_data::update_fstab

    # verify mount
    krun::mount::disk_data::verify_mount

    # show results
    krun::mount::disk_data::show_results

    echo -e "${GREEN}✅ Disk mounting completed successfully!${NC}"
    echo -e "${GREEN}💾 ${DISK_DEVICE} is now mounted at ${MOUNT_POINT}${NC}"
}

# check if running as root
krun::mount::disk_data::check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root${NC}"
        echo -e "${YELLOW}💡 Please run: sudo $0${NC}"
        exit 1
    fi
}

# install required tools
krun::mount::disk_data::install_tools() {
    echo -e "${BLUE}🔧 Installing required tools...${NC}"

    if command -v dnf >/dev/null 2>&1; then
        dnf install -y util-linux parted e2fsprogs xfsprogs
    elif command -v yum >/dev/null 2>&1; then
        yum install -y util-linux parted e2fsprogs xfsprogs
    elif command -v apt >/dev/null 2>&1; then
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y util-linux parted e2fsprogs xfsprogs
    else
        echo -e "${RED}❌ Unsupported package manager${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Required tools installed${NC}"
}

# safety checks before proceeding
krun::mount::disk_data::safety_checks() {
    echo -e "${BLUE}🔍 Performing safety checks...${NC}"

    # check if disk exists
    if [[ ! -b "$DISK_DEVICE" ]]; then
        echo -e "${RED}❌ Disk ${DISK_DEVICE} not found${NC}"
        echo -e "${YELLOW}💡 Available disks:${NC}"
        lsblk -d -n -o NAME,SIZE,TYPE | grep disk
        exit 1
    fi

    # check if disk is already mounted
    if mount | grep -q "$DISK_DEVICE"; then
        echo -e "${RED}❌ Disk ${DISK_DEVICE} is already mounted${NC}"
        mount | grep "$DISK_DEVICE"
        exit 1
    fi

    # check if mount point already exists and is in use
    if [[ -d "$MOUNT_POINT" ]] && mountpoint -q "$MOUNT_POINT"; then
        echo -e "${RED}❌ Mount point ${MOUNT_POINT} is already in use${NC}"
        df -h "$MOUNT_POINT"
        exit 1
    fi

    # check if disk has existing partitions
    if fdisk -l "$DISK_DEVICE" 2>/dev/null | grep -q "^${DISK_DEVICE}[0-9]"; then
        echo -e "${YELLOW}⚠️  Disk ${DISK_DEVICE} already has partitions - will be destroyed${NC}"
        fdisk -l "$DISK_DEVICE"
        echo -e "${RED}⚠️  Continuing automatically in 5 seconds...${NC}"
        sleep 5
    fi

    # show disk information
    echo -e "${GREEN}💾 Disk information:${NC}"
    lsblk "$DISK_DEVICE"
    echo ""

    # auto-execution warning
    echo -e "${YELLOW}⚠️  WARNING: Auto-formatting ${DISK_DEVICE} and mounting to ${MOUNT_POINT}${NC}"
    echo -e "${RED}⚠️  ALL DATA ON ${DISK_DEVICE} WILL BE LOST!${NC}"
    echo -e "${CYAN}🚀 Starting automatic disk mounting in 3 seconds...${NC}"
    sleep 3

    echo -e "${GREEN}✓ Safety checks passed${NC}"
}

# backup fstab
krun::mount::disk_data::backup_fstab() {
    echo -e "${BLUE}📋 Backing up /etc/fstab...${NC}"

    local backup_file="/etc/fstab.backup.$(date +%Y%m%d-%H%M%S)"
    cp /etc/fstab "$backup_file"

    echo -e "${GREEN}✓ fstab backed up to: $backup_file${NC}"
}

# partition the disk
krun::mount::disk_data::partition_disk() {
    echo -e "${BLUE}🔧 Partitioning disk ${DISK_DEVICE}...${NC}"

    # create partition table and single partition
    parted -s "$DISK_DEVICE" mklabel gpt
    parted -s "$DISK_DEVICE" mkpart primary "$FS_TYPE" 0% 100%

    # wait for kernel to recognize the partition
    sleep 2
    partprobe "$DISK_DEVICE"
    sleep 2

    # verify partition was created
    if [[ ! -b "$PARTITION_DEVICE" ]]; then
        echo -e "${RED}❌ Failed to create partition ${PARTITION_DEVICE}${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Partition created: ${PARTITION_DEVICE}${NC}"
}

# format the partition
krun::mount::disk_data::format_partition() {
    echo -e "${BLUE}🔧 Formatting partition ${PARTITION_DEVICE} with ${FS_TYPE}...${NC}"

    case "$FS_TYPE" in
    ext4)
        mkfs.ext4 -F "$PARTITION_DEVICE"
        ;;
    ext3)
        mkfs.ext3 -F "$PARTITION_DEVICE"
        ;;
    xfs)
        mkfs.xfs -f "$PARTITION_DEVICE"
        ;;
    *)
        echo -e "${RED}❌ Unsupported filesystem type: ${FS_TYPE}${NC}"
        exit 1
        ;;
    esac

    # set filesystem label
    case "$FS_TYPE" in
    ext4 | ext3)
        e2label "$PARTITION_DEVICE" "data"
        ;;
    xfs)
        xfs_admin -L "data" "$PARTITION_DEVICE"
        ;;
    esac

    echo -e "${GREEN}✓ Partition formatted with ${FS_TYPE}${NC}"
}

# create mount point
krun::mount::disk_data::create_mount_point() {
    echo -e "${BLUE}🔧 Creating mount point ${MOUNT_POINT}...${NC}"

    if [[ ! -d "$MOUNT_POINT" ]]; then
        mkdir -p "$MOUNT_POINT"
        echo -e "${GREEN}✓ Created directory: ${MOUNT_POINT}${NC}"
    else
        echo -e "${YELLOW}⚠️  Directory ${MOUNT_POINT} already exists${NC}"
    fi

    # set appropriate permissions
    chmod 755 "$MOUNT_POINT"
}

# mount the partition
krun::mount::disk_data::mount_partition() {
    echo -e "${BLUE}🔧 Mounting ${PARTITION_DEVICE} to ${MOUNT_POINT}...${NC}"

    mount "$PARTITION_DEVICE" "$MOUNT_POINT"

    # verify mount
    if ! mountpoint -q "$MOUNT_POINT"; then
        echo -e "${RED}❌ Failed to mount ${PARTITION_DEVICE}${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Partition mounted successfully${NC}"
}

# update fstab for persistent mounting
krun::mount::disk_data::update_fstab() {
    echo -e "${BLUE}🔧 Updating /etc/fstab...${NC}"

    # get UUID of the partition
    local uuid
    uuid=$(blkid -s UUID -o value "$PARTITION_DEVICE")

    if [[ -z "$uuid" ]]; then
        echo -e "${RED}❌ Failed to get UUID for ${PARTITION_DEVICE}${NC}"
        exit 1
    fi

    # prepare fstab entry
    local fstab_entry
    case "$FS_TYPE" in
    ext4)
        fstab_entry="UUID=${uuid} ${MOUNT_POINT} ${FS_TYPE} defaults,noatime,nodiratime 0 2"
        ;;
    ext3)
        fstab_entry="UUID=${uuid} ${MOUNT_POINT} ${FS_TYPE} defaults,noatime,nodiratime 0 2"
        ;;
    xfs)
        fstab_entry="UUID=${uuid} ${MOUNT_POINT} ${FS_TYPE} defaults,noatime,nodiratime 0 2"
        ;;
    *)
        fstab_entry="UUID=${uuid} ${MOUNT_POINT} ${FS_TYPE} defaults 0 2"
        ;;
    esac

    # check if entry already exists
    if grep -q "${MOUNT_POINT}" /etc/fstab; then
        echo -e "${YELLOW}⚠️  Entry for ${MOUNT_POINT} already exists in fstab${NC}"
        echo -e "${YELLOW}⚠️  Removing old entry...${NC}"
        sed -i "\|${MOUNT_POINT}|d" /etc/fstab
    fi

    # add new entry
    echo "" >>/etc/fstab
    echo "# Auto-generated entry for ${DISK_DEVICE} mounted to ${MOUNT_POINT}" >>/etc/fstab
    echo "$fstab_entry" >>/etc/fstab

    # test fstab
    if mount -a; then
        echo -e "${GREEN}✓ fstab updated successfully${NC}"
        echo -e "${GREEN}✓ UUID: ${uuid}${NC}"
    else
        echo -e "${RED}❌ fstab test failed${NC}"
        exit 1
    fi
}

# verify mount and permissions
krun::mount::disk_data::verify_mount() {
    echo -e "${BLUE}🔍 Verifying mount...${NC}"

    # check if mounted
    if mountpoint -q "$MOUNT_POINT"; then
        echo -e "${GREEN}✓ ${MOUNT_POINT} is properly mounted${NC}"
    else
        echo -e "${RED}❌ ${MOUNT_POINT} is not mounted${NC}"
        exit 1
    fi

    # test write permissions
    local test_file="${MOUNT_POINT}/.write_test"
    if echo "test" >"$test_file" 2>/dev/null; then
        rm -f "$test_file"
        echo -e "${GREEN}✓ Write permissions verified${NC}"
    else
        echo -e "${RED}❌ Write test failed${NC}"
        exit 1
    fi

    # check filesystem
    local fs_type
    fs_type=$(df -T "$MOUNT_POINT" | tail -1 | awk '{print $2}')
    echo -e "${GREEN}✓ Filesystem type: ${fs_type}${NC}"
}

# show results
krun::mount::disk_data::show_results() {
    echo -e "${BLUE}📊 Mount Information:${NC}"
    echo ""

    # show disk usage
    echo -e "${GREEN}💾 Disk Usage:${NC}"
    df -h "$MOUNT_POINT"
    echo ""

    # show mount options
    echo -e "${GREEN}🔧 Mount Options:${NC}"
    mount | grep "$MOUNT_POINT"
    echo ""

    # show block device info
    echo -e "${GREEN}📋 Block Device Info:${NC}"
    lsblk "$DISK_DEVICE"
    echo ""

    # show filesystem info
    echo -e "${GREEN}📁 Filesystem Info:${NC}"
    blkid "$PARTITION_DEVICE"
    echo ""

    # show fstab entry
    echo -e "${GREEN}📝 fstab Entry:${NC}"
    grep "$MOUNT_POINT" /etc/fstab
    echo ""

    echo -e "${GREEN}💡 Usage Examples:${NC}"
    echo "  cd $MOUNT_POINT                    # Navigate to data directory"
    echo "  mkdir $MOUNT_POINT/backups         # Create subdirectories"
    echo "  chown user:group $MOUNT_POINT      # Change ownership"
    echo "  chmod 755 $MOUNT_POINT             # Set permissions"
    echo ""

    echo -e "${YELLOW}📚 Notes:${NC}"
    echo "• Disk is mounted with 'noatime,nodiratime' for better performance"
    echo "• Mount point will persist after reboot via /etc/fstab"
    echo "• Backup of original fstab was created"
    echo "• Filesystem label is set to 'data'"
    echo ""
}

# run main
krun::mount::disk_data::run "$@"
