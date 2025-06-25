#!/usr/bin/env bash

# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/optimize-system-performance.sh | bash

# vars
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# run code
krun::optimize::system_performance::run() {
    echo -e "${BLUE}🚀 Starting system performance optimization...${NC}"

    # detect platform
    platform='debian'
    if command -v yum >/dev/null 2>&1; then
        platform='centos'
    elif command -v dnf >/dev/null 2>&1; then
        platform='centos'
    fi

    echo -e "${GREEN}📊 Detected platform: ${platform}${NC}"

    # backup original configs
    krun::optimize::system_performance::backup_configs

    # run platform specific optimizations
    eval "${FUNCNAME/::run/::${platform}}"

    # apply common optimizations
    krun::optimize::system_performance::common

    echo -e "${GREEN}✅ System performance optimization completed!${NC}"
    echo -e "${YELLOW}⚠️  Please reboot the system to apply all changes!${NC}"
}

# centos code
krun::optimize::system_performance::centos() {
    echo -e "${BLUE}🔧 Applying CentOS 9/RHEL optimizations...${NC}"

    # update system and install essential packages
    dnf update -y || yum update -y
    dnf install -y epel-release || yum install -y epel-release
    dnf install -y \
        htop \
        iotop \
        sysstat \
        tuned \
        irqbalance \
        numactl \
        bash-completion \
        vim \
        curl \
        wget \
        rsync \
        lsof \
        strace \
        tcpdump \
        nmap-ncat \
        bind-utils ||
        yum install -y \
            htop \
            iotop \
            sysstat \
            tuned \
            irqbalance \
            numactl \
            bash-completion \
            vim \
            curl \
            wget \
            rsync \
            lsof \
            strace \
            tcpdump \
            nmap-ncat \
            bind-utils

    # enable and start performance services
    systemctl enable --now tuned
    systemctl enable --now irqbalance

    # set tuned profile for better performance
    tuned-adm profile throughput-performance

    # disable unnecessary services
    local services_to_disable=(
        "bluetooth.service"
        "cups.service"
        "avahi-daemon.service"
        "ModemManager.service"
    )

    for service in "${services_to_disable[@]}"; do
        if systemctl is-enabled "$service" >/dev/null 2>&1; then
            systemctl disable "$service" || true
            echo -e "${GREEN}✓ Disabled service: $service${NC}"
        fi
    done

    # disable SELinux
    if [[ -f /etc/selinux/config ]]; then
        sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
        echo -e "${GREEN}✓ SELinux disabled (requires reboot)${NC}"
    fi

    # disable SELinux for current session
    if command -v setenforce >/dev/null 2>&1; then
        setenforce 0 2>/dev/null || true
        echo -e "${GREEN}✓ SELinux disabled for current session${NC}"
    fi
}

# debian code
krun::optimize::system_performance::debian() {
    echo -e "${BLUE}🔧 Applying Debian/Ubuntu optimizations...${NC}"

    # update system and install essential packages
    apt-get update
    apt-get upgrade -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        htop \
        iotop \
        sysstat \
        irqbalance \
        numactl \
        bash-completion \
        vim \
        curl \
        wget \
        rsync \
        lsof \
        strace \
        tcpdump \
        netcat-openbsd \
        dnsutils \
        cpufrequtils \
        linux-tools-common \
        linux-tools-generic

    # enable and start performance services
    systemctl enable --now irqbalance

    # configure CPU governor for performance
    if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]; then
        echo 'performance' | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null || true

        # make persistent
        echo 'GOVERNOR="performance"' >/etc/default/cpufrequtils
    fi

    # disable unnecessary services
    local services_to_disable=(
        "bluetooth.service"
        "cups.service"
        "avahi-daemon.service"
        "ModemManager.service"
        "whoopsie.service"
        "apport.service"
    )

    for service in "${services_to_disable[@]}"; do
        if systemctl is-enabled "$service" >/dev/null 2>&1; then
            systemctl disable "$service" || true
            echo -e "${GREEN}✓ Disabled service: $service${NC}"
        fi
    done

    # configure AppArmor (keep it enabled but optimized)
    if command -v aa-status >/dev/null 2>&1; then
        systemctl enable apparmor
    fi
}

# common code
krun::optimize::system_performance::common() {
    echo -e "${BLUE}🔧 Applying common performance optimizations...${NC}"

    # configure kernel parameters
    krun::optimize::system_performance::configure_sysctl

    # configure system limits
    krun::optimize::system_performance::configure_limits

    # optimize network settings
    krun::optimize::system_performance::optimize_network

    # configure file system optimizations
    krun::optimize::system_performance::optimize_filesystem

    # configure memory management
    krun::optimize::system_performance::optimize_memory

    # configure I/O scheduler
    krun::optimize::system_performance::optimize_io

    # set timezone to Asia/Shanghai
    timedatectl set-timezone Asia/Shanghai

    # enable time synchronization
    systemctl enable --now systemd-timesyncd ||
        systemctl enable --now chronyd ||
        systemctl enable --now ntpd || true

    # apply all changes
    sysctl -p /etc/sysctl.d/99-performance.conf || true

    echo -e "${GREEN}✅ Common optimizations applied successfully${NC}"
}

# backup original configurations
krun::optimize::system_performance::backup_configs() {
    echo -e "${BLUE}📋 Backing up original configurations...${NC}"

    local backup_dir="/root/krun-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    # backup important config files
    local configs_to_backup=(
        "/etc/sysctl.conf"
        "/etc/security/limits.conf"
        "/etc/systemd/system.conf"
        "/etc/fstab"
    )

    for config in "${configs_to_backup[@]}"; do
        if [[ -f "$config" ]]; then
            cp "$config" "$backup_dir/" 2>/dev/null || true
        fi
    done

    echo -e "${GREEN}✓ Configurations backed up to: $backup_dir${NC}"
}

# configure kernel parameters
krun::optimize::system_performance::configure_sysctl() {
    echo -e "${BLUE}🔧 Configuring kernel parameters...${NC}"

    cat >/etc/sysctl.d/99-performance.conf <<'EOF'
# Kernel performance optimizations

# Virtual memory settings
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500
vm.overcommit_memory = 1
vm.overcommit_ratio = 50
vm.vfs_cache_pressure = 50
vm.min_free_kbytes = 65536

# Network performance
net.core.rmem_default = 262144
net.core.rmem_max = 67108864
net.core.wmem_default = 262144
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 5000
net.core.netdev_budget = 600
net.core.somaxconn = 65535
net.core.optmem_max = 81920

# TCP settings
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_tw_buckets = 1048576
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_adv_win_scale = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_frto = 2
net.ipv4.tcp_no_metrics_save = 1

# IP settings
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.ip_forward = 0

# File system
fs.file-max = 2097152
fs.nr_open = 1048576
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 256

# Kernel settings
kernel.pid_max = 4194304
kernel.threads-max = 2097152
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.panic = 10
kernel.hung_task_timeout_secs = 0

# Security settings
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1
kernel.unprivileged_bpf_disabled = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
EOF

    echo -e "${GREEN}✓ Kernel parameters configured${NC}"
}

# configure system limits
krun::optimize::system_performance::configure_limits() {
    echo -e "${BLUE}🔧 Configuring system limits...${NC}"

    cat >/etc/security/limits.d/99-performance.conf <<'EOF'
# System performance limits

# Hard and soft limits for all users
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 1048576
* hard nproc 1048576
* soft memlock unlimited
* hard memlock unlimited
* soft stack 8192
* hard stack 8192

# Root user limits
root soft nofile 1048576
root hard nofile 1048576
root soft nproc 1048576
root hard nproc 1048576
root soft memlock unlimited
root hard memlock unlimited
EOF

    # configure systemd limits
    if [[ -f /etc/systemd/system.conf ]]; then
        sed -i 's/#DefaultLimitNOFILE=.*/DefaultLimitNOFILE=1048576/' /etc/systemd/system.conf
        sed -i 's/#DefaultLimitNPROC=.*/DefaultLimitNPROC=1048576/' /etc/systemd/system.conf
        sed -i 's/#DefaultLimitMEMLOCK=.*/DefaultLimitMEMLOCK=infinity/' /etc/systemd/system.conf
        systemctl daemon-reload
    fi

    echo -e "${GREEN}✓ System limits configured${NC}"
}

# optimize network settings
krun::optimize::system_performance::optimize_network() {
    echo -e "${BLUE}🔧 Optimizing network settings...${NC}"

    # configure network buffer sizes
    if [[ -f /proc/sys/net/core/rmem_max ]]; then
        echo 67108864 >/proc/sys/net/core/rmem_max
        echo 67108864 >/proc/sys/net/core/wmem_max
    fi

    # enable BBR congestion control if available
    if modprobe tcp_bbr 2>/dev/null; then
        echo "tcp_bbr" >>/etc/modules-load.d/bbr.conf
        echo -e "${GREEN}✓ BBR congestion control enabled${NC}"
    fi

    echo -e "${GREEN}✓ Network settings optimized${NC}"
}

# optimize filesystem settings
krun::optimize::system_performance::optimize_filesystem() {
    echo -e "${BLUE}🔧 Optimizing filesystem settings...${NC}"

    # update /etc/fstab with performance options
    if [[ -f /etc/fstab ]]; then
        # backup fstab
        cp /etc/fstab /etc/fstab.bak.$(date +%Y%m%d)

        # add noatime option to reduce disk I/O
        sed -i 's/\(.*ext[234].*\)defaults\(.*\)/\1defaults,noatime,nodiratime\2/' /etc/fstab
        sed -i 's/\(.*xfs.*\)defaults\(.*\)/\1defaults,noatime,nodiratime\2/' /etc/fstab
    fi

    # configure readahead for better I/O performance
    if command -v blockdev >/dev/null 2>&1; then
        for device in $(lsblk -nd -o NAME | grep -E '^(sd|nvme|vd)'); do
            blockdev --setra 4096 "/dev/$device" 2>/dev/null || true
        done
    fi

    echo -e "${GREEN}✓ Filesystem settings optimized${NC}"
}

# optimize memory management
krun::optimize::system_performance::optimize_memory() {
    echo -e "${BLUE}🔧 Optimizing memory management...${NC}"

    # configure transparent huge pages
    if [[ -f /sys/kernel/mm/transparent_hugepage/enabled ]]; then
        echo never >/sys/kernel/mm/transparent_hugepage/enabled
        echo never >/sys/kernel/mm/transparent_hugepage/defrag

        # make it persistent
        cat >/etc/systemd/system/disable-thp.service <<'EOF'
[Unit]
Description=Disable Transparent Huge Pages
DefaultDependencies=false
After=sysinit.target local-fs.target
Before=mongod.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo never | tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null'
ExecStart=/bin/sh -c 'echo never | tee /sys/kernel/mm/transparent_hugepage/defrag > /dev/null'

[Install]
WantedBy=basic.target
EOF
        systemctl enable disable-thp.service
        echo -e "${GREEN}✓ Transparent Huge Pages disabled${NC}"
    fi

    # configure NUMA balancing
    if [[ -f /proc/sys/kernel/numa_balancing ]]; then
        echo 1 >/proc/sys/kernel/numa_balancing
    fi

    echo -e "${GREEN}✓ Memory management optimized${NC}"
}

# optimize I/O scheduler
krun::optimize::system_performance::optimize_io() {
    echo -e "${BLUE}🔧 Optimizing I/O scheduler...${NC}"

    # set appropriate I/O scheduler for different storage types
    for device in $(lsblk -nd -o NAME,ROTA | awk '$2==0 {print $1}'); do
        # SSD devices - use deadline or noop
        if [[ -f "/sys/block/$device/queue/scheduler" ]]; then
            if grep -q "mq-deadline" "/sys/block/$device/queue/scheduler"; then
                echo "mq-deadline" >"/sys/block/$device/queue/scheduler"
            elif grep -q "deadline" "/sys/block/$device/queue/scheduler"; then
                echo "deadline" >"/sys/block/$device/queue/scheduler"
            elif grep -q "noop" "/sys/block/$device/queue/scheduler"; then
                echo "noop" >"/sys/block/$device/queue/scheduler"
            fi
            echo -e "${GREEN}✓ Set scheduler for SSD device: $device${NC}"
        fi
    done

    for device in $(lsblk -nd -o NAME,ROTA | awk '$2==1 {print $1}'); do
        # HDD devices - use cfq
        if [[ -f "/sys/block/$device/queue/scheduler" ]]; then
            if grep -q "cfq" "/sys/block/$device/queue/scheduler"; then
                echo "cfq" >"/sys/block/$device/queue/scheduler"
            elif grep -q "bfq" "/sys/block/$device/queue/scheduler"; then
                echo "bfq" >"/sys/block/$device/queue/scheduler"
            fi
            echo -e "${GREEN}✓ Set scheduler for HDD device: $device${NC}"
        fi
    done

    # create udev rules for persistent I/O scheduler settings
    cat >/etc/udev/rules.d/60-ioschedulers.rules <<'EOF'
# Set deadline scheduler for non-rotating disks
ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]n[0-9]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
# Set cfq scheduler for rotating disks
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="cfq"
EOF

    echo -e "${GREEN}✓ I/O scheduler optimized${NC}"
}

# run main
krun::optimize::system_performance::run "$@"
