#!/usr/bin/env bash
# Copyright (c) 2025 kk
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
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# System configuration parameters
readonly SYSCTL_PARAMS=(
    # Virtual memory settings
    "vm.swappiness=10"
    "vm.dirty_ratio=15"
    "vm.dirty_background_ratio=5"
    "vm.dirty_expire_centisecs=3000"
    "vm.dirty_writeback_centisecs=500"
    "vm.overcommit_memory=1"
    "vm.overcommit_ratio=50"
    "vm.vfs_cache_pressure=50"
    "vm.min_free_kbytes=65536"

    # Network performance
    "net.core.rmem_default=262144"
    "net.core.rmem_max=67108864"
    "net.core.wmem_default=262144"
    "net.core.wmem_max=67108864"
    "net.core.netdev_max_backlog=5000"
    "net.core.netdev_budget=600"
    "net.core.somaxconn=65535"
    "net.core.optmem_max=81920"

    # TCP settings
    "net.ipv4.tcp_rmem=4096 87380 67108864"
    "net.ipv4.tcp_wmem=4096 65536 67108864"
    "net.ipv4.tcp_congestion_control=bbr"
    "net.ipv4.tcp_slow_start_after_idle=0"
    "net.ipv4.tcp_keepalive_time=600"
    "net.ipv4.tcp_keepalive_intvl=60"
    "net.ipv4.tcp_keepalive_probes=3"
    "net.ipv4.tcp_fin_timeout=30"
    "net.ipv4.tcp_tw_reuse=1"
    "net.ipv4.tcp_max_tw_buckets=1048576"
    "net.ipv4.tcp_max_syn_backlog=8192"
    "net.ipv4.tcp_syncookies=1"
    "net.ipv4.tcp_synack_retries=2"
    "net.ipv4.tcp_syn_retries=2"
    "net.ipv4.tcp_sack=1"
    "net.ipv4.tcp_fack=1"
    "net.ipv4.tcp_timestamps=1"
    "net.ipv4.tcp_window_scaling=1"
    "net.ipv4.tcp_adv_win_scale=1"
    "net.ipv4.tcp_low_latency=1"
    "net.ipv4.tcp_frto=2"
    "net.ipv4.tcp_no_metrics_save=1"

    # IP settings
    "net.ipv4.ip_local_port_range=1024 65535"
    "net.ipv4.ip_forward=1"          # Enable IP forwarding
    "net.ipv4.conf.all.forwarding=1" # Enable IPv4 forwarding on all interfaces
    "net.ipv6.conf.all.forwarding=1" # Enable IPv6 forwarding on all interfaces
    "net.ipv4.conf.all.accept_redirects=0"
    "net.ipv4.conf.default.accept_redirects=0"
    "net.ipv4.conf.all.secure_redirects=0"
    "net.ipv4.conf.default.secure_redirects=0"
    "net.ipv4.conf.all.send_redirects=1"     # Allow sending ICMP redirects
    "net.ipv4.conf.default.send_redirects=1" # Allow sending ICMP redirects
    "net.ipv4.conf.all.accept_source_route=0"
    "net.ipv4.conf.default.accept_source_route=0"
    "net.ipv4.conf.all.log_martians=1"
    "net.ipv4.conf.default.log_martians=1"
    "net.ipv4.icmp_echo_ignore_broadcasts=1"
    "net.ipv4.icmp_ignore_bogus_error_responses=1"

    # File system
    "fs.file-max=2097152"
    "fs.nr_open=1048576"
    "fs.inotify.max_user_watches=524288"
    "fs.inotify.max_user_instances=256"

    # Kernel settings
    "kernel.pid_max=4194304"
    "kernel.threads-max=2097152"
    "kernel.shmmax=68719476736"
    "kernel.shmall=4294967296"
    "kernel.msgmnb=65536"
    "kernel.msgmax=65536"
    "kernel.panic=10"
    "kernel.hung_task_timeout_secs=0"

    # Security settings
    "kernel.dmesg_restrict=1"
    "kernel.kptr_restrict=2"
    "kernel.yama.ptrace_scope=1"
    "kernel.unprivileged_bpf_disabled=1"
    "net.ipv4.conf.all.rp_filter=1"
    "net.ipv4.conf.default.rp_filter=1"
)

# run code
krun::optimize::system_performance::run() {
    echo -e "${BLUE}🚀 Starting system performance optimization...${NC}"

    # Check if script has been run before
    if [[ -f /etc/sysctl.d/99-performance.conf ]] || [[ -f /etc/security/limits.d/99-performance.conf ]]; then
        echo -e "${YELLOW}⚠️  Optimization files detected - this appears to be a repeated run${NC}"
        echo -e "${BLUE}📋 Script will safely update existing configurations${NC}"
    fi

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

    # configure development and ops tools
    krun::optimize::system_performance::configure_tools

    echo -e "${GREEN}✅ System performance optimization completed!${NC}"
    echo -e "${BLUE}🔄 This script is idempotent and safe to run multiple times${NC}"
    echo -e "${YELLOW}⚠️  Please reboot the system to apply all changes!${NC}"

    # Show summary of what was configured
    echo -e "\n${CYAN}📋 Configuration Summary:${NC}"
    echo -e "${BLUE}  - Kernel parameters: /etc/sysctl.d/99-performance.conf${NC}"
    echo -e "${BLUE}  - System limits: /etc/security/limits.d/99-performance.conf${NC}"
    echo -e "${BLUE}  - Vim configuration: /etc/vim/vimrc.local${NC}"
    echo -e "${BLUE}  - Tmux configuration: /etc/tmux.conf${NC}"
    echo -e "${BLUE}  - Bash aliases: /etc/profile.d/ops-aliases.sh${NC}"
    if [[ -f /etc/modules-load.d/bbr.conf ]]; then
        echo -e "${BLUE}  - BBR congestion control: enabled${NC}"
    fi
    if systemctl is-enabled disable-thp.service >/dev/null 2>&1; then
        echo -e "${BLUE}  - Transparent Huge Pages: disabled${NC}"
    fi
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
        vim-enhanced \
        curl \
        wget \
        rsync \
        lsof \
        strace \
        tcpdump \
        nmap-ncat \
        bind-utils \
        git \
        tree \
        unzip \
        zip \
        screen \
        tmux \
        net-tools \
        telnet \
        traceroute \
        mtr \
        iperf3 \
        jq \
        ncdu \
        tar \
        gzip \
        bzip2 \
        xz \
        which \
        nano \
        less \
        grep \
        sed \
        awk \
        find \
        psmisc \
        procps-ng \
        util-linux \
        coreutils \
        iftop \
        nethogs \
        nmon \
        dstat \
        atop \
        glances \
        multitail \
        parallel ||
        yum install -y \
            htop \
            iotop \
            sysstat \
            tuned \
            irqbalance \
            numactl \
            bash-completion \
            vim \
            vim-enhanced \
            curl \
            wget \
            rsync \
            lsof \
            strace \
            tcpdump \
            nmap-ncat \
            bind-utils \
            git \
            tree \
            unzip \
            zip \
            screen \
            tmux \
            net-tools \
            telnet \
            traceroute \
            mtr \
            iperf3 \
            jq \
            ncdu \
            tar \
            gzip \
            bzip2 \
            xz \
            which \
            nano \
            less \
            grep \
            sed \
            gawk \
            findutils \
            psmisc \
            procps-ng \
            util-linux \
            coreutils \
            iftop \
            nethogs \
            nmon \
            dstat \
            atop \
            glances \
            multitail \
            parallel

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
        if grep -q "^SELINUX=disabled" /etc/selinux/config; then
            echo -e "${GREEN}✓ SELinux already disabled in config${NC}"
        else
            sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
            echo -e "${GREEN}✓ SELinux disabled (requires reboot)${NC}"
        fi
    fi

    # disable SELinux for current session
    if command -v setenforce >/dev/null 2>&1; then
        if getenforce 2>/dev/null | grep -q "Disabled\|Permissive"; then
            echo -e "${GREEN}✓ SELinux already disabled for current session${NC}"
        else
            setenforce 0 2>/dev/null || true
            echo -e "${GREEN}✓ SELinux disabled for current session${NC}"
        fi
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
        vim-nox \
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
        linux-tools-generic \
        git \
        tree \
        unzip \
        zip \
        screen \
        tmux \
        net-tools \
        telnet \
        traceroute \
        mtr-tiny \
        iperf3 \
        jq \
        ncdu \
        tar \
        gzip \
        bzip2 \
        xz-utils \
        nano \
        less \
        grep \
        sed \
        gawk \
        findutils \
        psmisc \
        procps \
        util-linux \
        coreutils \
        iftop \
        nethogs \
        nmon \
        dstat \
        atop \
        glances \
        multitail \
        parallel

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
    echo -e "${BLUE}🕐 Setting timezone to Asia/Shanghai...${NC}"

    # Method 1: Try timedatectl (systemd)
    if command -v timedatectl >/dev/null 2>&1; then
        if timedatectl set-timezone Asia/Shanghai 2>/dev/null; then
            echo -e "${GREEN}✓ Timezone set to Asia/Shanghai using timedatectl${NC}"
        else
            echo -e "${YELLOW}⚠️  timedatectl failed, trying alternative method${NC}"
            # Method 2: Manual timezone file copy
            if [[ -f /usr/share/zoneinfo/Asia/Shanghai ]]; then
                ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
                echo 'Asia/Shanghai' >/etc/timezone 2>/dev/null || true
                echo -e "${GREEN}✓ Timezone set to Asia/Shanghai using manual method${NC}"
            else
                echo -e "${RED}✗ Failed to set timezone: /usr/share/zoneinfo/Asia/Shanghai not found${NC}"
            fi
        fi
    else
        # Method 2: Manual timezone file copy for systems without timedatectl
        echo -e "${BLUE}timedatectl not available, using manual method...${NC}"
        if [[ -f /usr/share/zoneinfo/Asia/Shanghai ]]; then
            ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
            echo 'Asia/Shanghai' >/etc/timezone 2>/dev/null || true
            echo -e "${GREEN}✓ Timezone set to Asia/Shanghai using manual method${NC}"
        else
            echo -e "${RED}✗ Failed to set timezone: /usr/share/zoneinfo/Asia/Shanghai not found${NC}"
        fi
    fi

    # Verify timezone setting
    if command -v timedatectl >/dev/null 2>&1; then
        echo -e "${BLUE}Current timezone status:${NC}"
        timedatectl status | grep -E "(Time zone|Local time)" || true
    else
        echo -e "${BLUE}Current timezone: $(cat /etc/timezone 2>/dev/null || readlink /etc/localtime | sed 's|/usr/share/zoneinfo/||')${NC}"
        echo -e "${BLUE}Current local time: $(date)${NC}"
    fi

    # enable time synchronization
    echo -e "${BLUE}🕐 Configuring time synchronization...${NC}"
    if systemctl list-unit-files | grep -q systemd-timesyncd; then
        if systemctl is-active systemd-timesyncd >/dev/null 2>&1; then
            echo -e "${GREEN}✓ systemd-timesyncd already active${NC}"
        else
            systemctl enable --now systemd-timesyncd
            echo -e "${GREEN}✓ systemd-timesyncd enabled${NC}"
        fi
    elif systemctl list-unit-files | grep -q chronyd; then
        if systemctl is-active chronyd >/dev/null 2>&1; then
            echo -e "${GREEN}✓ chronyd already active${NC}"
        else
            systemctl enable --now chronyd
            echo -e "${GREEN}✓ chronyd enabled${NC}"
        fi
    elif systemctl list-unit-files | grep -q ntpd; then
        if systemctl is-active ntpd >/dev/null 2>&1; then
            echo -e "${GREEN}✓ ntpd already active${NC}"
        else
            systemctl enable --now ntpd
            echo -e "${GREEN}✓ ntpd enabled${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No time synchronization service found${NC}"
    fi

    # apply all changes
    sysctl -p /etc/sysctl.d/99-performance.conf || true

    echo -e "${GREEN}✅ Common optimizations applied successfully${NC}"
}

# backup original configurations
krun::optimize::system_performance::backup_configs() {
    echo -e "${BLUE}📋 Backing up original configurations...${NC}"

    # Check if backup already exists (avoid multiple backups on repeated runs)
    local existing_backup=$(find /root -maxdepth 1 -name "krun-backup-*" -type d | head -1)
    if [[ -n "$existing_backup" ]]; then
        echo -e "${YELLOW}⚠️  Backup already exists: $existing_backup${NC}"
        echo -e "${BLUE}Skipping backup to avoid duplicates${NC}"
        return
    fi

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
        local need_reload=false

        # Only modify if not already set
        if ! grep -q "^DefaultLimitNOFILE=1048576" /etc/systemd/system.conf; then
            sed -i 's/#DefaultLimitNOFILE=.*/DefaultLimitNOFILE=1048576/' /etc/systemd/system.conf
            sed -i 's/^DefaultLimitNOFILE=.*/DefaultLimitNOFILE=1048576/' /etc/systemd/system.conf
            need_reload=true
        fi

        if ! grep -q "^DefaultLimitNPROC=1048576" /etc/systemd/system.conf; then
            sed -i 's/#DefaultLimitNPROC=.*/DefaultLimitNPROC=1048576/' /etc/systemd/system.conf
            sed -i 's/^DefaultLimitNPROC=.*/DefaultLimitNPROC=1048576/' /etc/systemd/system.conf
            need_reload=true
        fi

        if ! grep -q "^DefaultLimitMEMLOCK=infinity" /etc/systemd/system.conf; then
            sed -i 's/#DefaultLimitMEMLOCK=.*/DefaultLimitMEMLOCK=infinity/' /etc/systemd/system.conf
            sed -i 's/^DefaultLimitMEMLOCK=.*/DefaultLimitMEMLOCK=infinity/' /etc/systemd/system.conf
            need_reload=true
        fi

        if [[ "$need_reload" == "true" ]]; then
            systemctl daemon-reload
            echo -e "${GREEN}✓ SystemD limits updated${NC}"
        else
            echo -e "${GREEN}✓ SystemD limits already configured${NC}"
        fi
    fi

    echo -e "${GREEN}✓ System limits configured${NC}"
}

# optimize network settings
krun::optimize::system_performance::optimize_network() {
    echo -e "${BLUE}🔧 Optimizing network settings...${NC}"

    # Configure network buffer sizes
    if [[ -f /proc/sys/net/core/rmem_max ]]; then
        echo 67108864 >/proc/sys/net/core/rmem_max
        echo 67108864 >/proc/sys/net/core/wmem_max
    fi

    # Enable IP forwarding immediately
    echo -e "${BLUE}🌐 Enabling IP forwarding...${NC}"
    if [[ -f /proc/sys/net/ipv4/ip_forward ]]; then
        echo 1 >/proc/sys/net/ipv4/ip_forward
        echo -e "${GREEN}✓ IPv4 forwarding enabled${NC}"
    fi

    if [[ -f /proc/sys/net/ipv4/conf/all/forwarding ]]; then
        echo 1 >/proc/sys/net/ipv4/conf/all/forwarding
        echo -e "${GREEN}✓ IPv4 forwarding enabled on all interfaces${NC}"
    fi

    if [[ -f /proc/sys/net/ipv6/conf/all/forwarding ]]; then
        echo 1 >/proc/sys/net/ipv6/conf/all/forwarding
        echo -e "${GREEN}✓ IPv6 forwarding enabled on all interfaces${NC}"
    fi

    # Enable BBR congestion control if available
    if lsmod | grep -q tcp_bbr; then
        echo -e "${GREEN}✓ BBR congestion control already loaded${NC}"
    elif modprobe tcp_bbr 2>/dev/null; then
        # Add to modules-load.d only if not already present
        if [[ ! -f /etc/modules-load.d/bbr.conf ]] || ! grep -q "tcp_bbr" /etc/modules-load.d/bbr.conf; then
            mkdir -p /etc/modules-load.d
            echo "tcp_bbr" >>/etc/modules-load.d/bbr.conf
        fi
        echo -e "${GREEN}✓ BBR congestion control enabled${NC}"
    else
        echo -e "${YELLOW}⚠️  BBR congestion control not available${NC}"
    fi

    # Verify IP forwarding status
    echo -e "${BLUE}📊 IP Forwarding Status:${NC}"
    if [[ -f /proc/sys/net/ipv4/ip_forward ]]; then
        echo -e "IPv4 Forwarding: $(cat /proc/sys/net/ipv4/ip_forward)"
    fi
    if [[ -f /proc/sys/net/ipv6/conf/all/forwarding ]]; then
        echo -e "IPv6 Forwarding: $(cat /proc/sys/net/ipv6/conf/all/forwarding)"
    fi

    echo -e "${GREEN}✓ Network settings optimized${NC}"
}

# optimize filesystem settings
krun::optimize::system_performance::optimize_filesystem() {
    echo -e "${BLUE}🔧 Optimizing filesystem settings...${NC}"

    # update /etc/fstab with performance options
    if [[ -f /etc/fstab ]]; then
        # Check if performance options are already added
        if grep -q "noatime" /etc/fstab; then
            echo -e "${GREEN}✓ fstab already optimized with noatime${NC}"
        else
            # backup fstab only if not already backed up
            if [[ ! -f /etc/fstab.bak.* ]]; then
                cp /etc/fstab /etc/fstab.bak.$(date +%Y%m%d)
            fi

            # add noatime option to reduce disk I/O
            sed -i 's/\(.*ext[234].*\)defaults\(.*\)/\1defaults,noatime,nodiratime\2/' /etc/fstab
            sed -i 's/\(.*xfs.*\)defaults\(.*\)/\1defaults,noatime,nodiratime\2/' /etc/fstab
            echo -e "${GREEN}✓ fstab optimized with noatime options${NC}"
        fi
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
        if [[ ! -f /etc/systemd/system/disable-thp.service ]]; then
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
        fi

        if ! systemctl is-enabled disable-thp.service >/dev/null 2>&1; then
            systemctl enable disable-thp.service
        fi
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

# configure development and ops tools
krun::optimize::system_performance::configure_tools() {
    echo -e "${BLUE}🔧 Configuring development and ops tools...${NC}"

    # configure vim
    krun::optimize::system_performance::configure_vim

    # configure git
    krun::optimize::system_performance::configure_git

    # configure tmux
    krun::optimize::system_performance::configure_tmux

    # configure bash aliases
    krun::optimize::system_performance::configure_bash_aliases

    echo -e "${GREEN}✓ Development and ops tools configured${NC}"
}

# configure vim for better ops experience
krun::optimize::system_performance::configure_vim() {
    echo -e "${BLUE}🔧 Configuring Vim...${NC}"

    # ensure vim directory exists
    mkdir -p /etc/vim

    # create global vimrc
    cat >/etc/vim/vimrc.local <<'EOF'
" Enhanced Vim configuration for DevOps

" Basic settings
set nocompatible              " Use Vim defaults
set encoding=utf-8            " UTF-8 encoding
set fileencoding=utf-8        " File encoding

" UI settings
set number                    " Show line numbers
set relativenumber            " Show relative line numbers
set ruler                     " Show cursor position
set showcmd                   " Show command in status line
set wildmenu                  " Enhanced command completion
set laststatus=2              " Always show status line
set scrolloff=8               " Keep 8 lines when scrolling
set sidescrolloff=15          " Keep 15 columns when side scrolling

" Indentation and formatting
set autoindent                " Auto indentation
set smartindent               " Smart indentation
set tabstop=4                 " Tab width
set shiftwidth=4              " Shift width
set expandtab                 " Use spaces instead of tabs
set softtabstop=4             " Soft tab stop
set backspace=indent,eol,start " Backspace behavior

" Search settings
set hlsearch                  " Highlight search results
set incsearch                 " Incremental search
set ignorecase                " Case insensitive search
set smartcase                 " Smart case sensitivity

" Backup and swap
set nobackup                  " No backup files
set noswapfile                " No swap files
set undofile                  " Persistent undo
set undodir=/tmp/vim-undo     " Undo directory

" File handling
set autoread                  " Auto reload files
set hidden                    " Allow hidden buffers

" Syntax and colors
syntax enable                 " Enable syntax highlighting
set background=dark           " Dark background
colorscheme default           " Default color scheme

" Key mappings
nnoremap <Space> <Nop>
let mapleader = " "           " Space as leader key

" Quick save and quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>

" Buffer navigation
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprev<CR>
nnoremap <leader>bd :bdelete<CR>

" Split navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Clear search highlight
nnoremap <leader>/ :nohlsearch<CR>

" Paste mode settings
set pastetoggle=<F2>          " Toggle paste mode with F2
nnoremap <leader>p :set paste!<CR>:set paste?<CR>  " Toggle paste with leader+p

" Clipboard settings
if has('clipboard')
    if has('unnamedplus')
        set clipboard=unnamed,unnamedplus  " Use system clipboard
    else
        set clipboard=unnamed
    endif
endif

" Better paste behavior
nnoremap <leader>P "+P       " Paste from system clipboard before cursor
nnoremap <leader>y "+y       " Yank to system clipboard
vnoremap <leader>y "+y       " Yank selection to system clipboard
vnoremap <leader>d "+d       " Delete to system clipboard

" Paste without overwriting register in visual mode
vnoremap p "_dP

" Better indentation in visual mode
vnoremap < <gv
vnoremap > >gv

" File type specific settings
autocmd FileType yaml setlocal tabstop=2 shiftwidth=2 softtabstop=2
autocmd FileType yml setlocal tabstop=2 shiftwidth=2 softtabstop=2
autocmd FileType json setlocal tabstop=2 shiftwidth=2 softtabstop=2
autocmd FileType sh setlocal tabstop=4 shiftwidth=4 softtabstop=4
autocmd FileType python setlocal tabstop=4 shiftwidth=4 softtabstop=4
autocmd FileType go setlocal tabstop=4 shiftwidth=4 noexpandtab

" Status line with paste mode indicator
set statusline=%f\ %m%r%h%w\ [%{&ff}]\ [%Y]\ %{&paste?'[PASTE]':''}\ [%04l,%04v]\ [%p%%]\ [%L\ lines]

" Auto create undo directory
if !isdirectory('/tmp/vim-undo')
    call mkdir('/tmp/vim-undo', 'p', 0700)
endif

" Auto commands for paste mode
augroup PasteMode
    autocmd!
    " Show paste mode in status line
    autocmd InsertEnter * if &paste | echo 'PASTE MODE ENABLED' | endif
    autocmd InsertLeave * if &paste | echo 'PASTE MODE ENABLED (Insert mode left)' | endif
augroup END

" Function to toggle paste mode with visual feedback
function! TogglePaste()
    if &paste
        set nopaste
        echo 'Paste mode: OFF'
    else
        set paste
        echo 'Paste mode: ON'
    endif
endfunction

" Map function to key
nnoremap <leader>tp :call TogglePaste()<CR>

" Auto-detect paste mode when pasting large amounts of text
if &term =~ "xterm.*" || &term =~ "screen.*" || &term =~ "tmux.*"
    let &t_SI = "\e[6 q"
    let &t_EI = "\e[2 q"
    " Enable bracketed paste mode for auto-detection
    let &t_BE = "\e[?2004h"
    let &t_BD = "\e[?2004l"
    exec "set t_PS=\e[200~"
    exec "set t_PE=\e[201~"

    " Auto-enable paste mode when bracketed paste is detected
    inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()

    function! XTermPasteBegin()
        set paste
        return ""
    endfunction

    " Auto-disable paste mode when bracketed paste ends
    autocmd InsertLeave * if &paste | set nopaste | echo 'Auto paste mode: OFF' | endif
endif

" Additional auto-paste detection for common terminals
if has('patch-8.0.0210') || has('nvim')
    " Modern vim/neovim with better paste detection
    if &term =~ "xterm" || &term =~ "screen" || &term =~ "tmux"
        " Enable automatic paste mode detection
        let &t_BE = "\<Esc>[?2004h"
        let &t_BD = "\<Esc>[?2004l"

        " Function to handle paste start
        function! PasteStart()
            set paste
            echo 'Auto paste mode: ON'
            return ""
        endfunction

        " Function to handle paste end
        function! PasteEnd()
            set nopaste
            echo 'Auto paste mode: OFF'
            return ""
        endfunction

        " Map the bracketed paste sequences
        noremap <special> <expr> <Esc>[200~ PasteStart()
        noremap <special> <expr> <Esc>[201~ PasteEnd()
        inoremap <special> <expr> <Esc>[200~ PasteStart()
        inoremap <special> <expr> <Esc>[201~ PasteEnd()
    endif
endif

" Smart paste detection based on input speed and content
augroup SmartPaste
    autocmd!
    " Detect rapid input (likely paste) and enable paste mode
    autocmd InsertCharPre * call SmartPasteDetection()
augroup END

let g:paste_detection_chars = 0
let g:paste_detection_time = 0

function! SmartPasteDetection()
    let current_time = localtime()
    let time_diff = current_time - g:paste_detection_time

    " If multiple characters are being inserted rapidly (within 1 second)
    if time_diff <= 1
        let g:paste_detection_chars += 1
        " If more than 10 characters in 1 second, likely a paste operation
        if g:paste_detection_chars > 10 && !&paste
            set paste
            echo 'Smart paste mode: ON (detected rapid input)'
        endif
    else
        " Reset counter if time gap is too large
        let g:paste_detection_chars = 0
    endif

    let g:paste_detection_time = current_time
endfunction

" Auto-disable paste mode after a period of inactivity
augroup AutoDisablePaste
    autocmd!
    autocmd CursorHoldI * if &paste | call AutoDisablePasteMode() | endif
    autocmd CursorHold * if &paste | call AutoDisablePasteMode() | endif
augroup END

function! AutoDisablePasteMode()
    " Disable paste mode after 3 seconds of inactivity
    sleep 3
    if &paste && mode() == 'n'
        set nopaste
        echo 'Auto paste mode: OFF (timeout)'
    endif
endfunction
EOF

    # create user-specific vimrc for root
    if [[ ! -f /root/.vimrc ]]; then
        cat >/root/.vimrc <<'EOF'
" Personal Vim configuration
source /etc/vim/vimrc.local

" Additional personal settings can go here

" Quick reference for paste mode:
" F2                - Toggle paste mode manually
" <leader>p         - Toggle paste mode with status
" <leader>tp        - Toggle paste mode with visual feedback
" <leader>y         - Yank to system clipboard
" <leader>P         - Paste from system clipboard before cursor
"
" AUTO PASTE MODE (NEW):
" - Automatically detects when you paste content
" - Works with modern terminals (xterm, screen, tmux)
" - Smart detection based on input speed (>10 chars/sec)
" - Auto-disables after leaving insert mode or timeout
" - No manual intervention needed for most paste operations
"
" In paste mode:
" - Auto-indentation is disabled
" - No text formatting
" - Mappings are disabled
" - Perfect for pasting code from external sources
"
" Detection methods:
" 1. Bracketed paste mode (modern terminals)
" 2. Smart input speed detection
" 3. Manual toggle (F2, <leader>p, <leader>tp)
EOF
    fi

    echo -e "${GREEN}✓ Vim configured${NC}"
}

# configure git global settings
krun::optimize::system_performance::configure_git() {
    echo -e "${BLUE}🔧 Configuring Git...${NC}"

    # global git configuration
    git config --global init.defaultBranch main
    git config --global core.editor vim
    git config --global color.ui auto
    git config --global push.default simple
    git config --global pull.rebase false

    # useful git aliases
    git config --global alias.st status
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.lg "log --oneline --graph --decorate --all"
    git config --global alias.last "log -1 HEAD"
    git config --global alias.unstage "reset HEAD --"

    echo -e "${GREEN}✓ Git configured${NC}"
}

# configure tmux
krun::optimize::system_performance::configure_tmux() {
    echo -e "${BLUE}🔧 Configuring Tmux...${NC}"

    cat >/etc/tmux.conf <<'EOF'
# Enhanced Tmux configuration for DevOps

# Basic settings
set -g default-terminal "screen-256color"
set -g history-limit 10000
set -g mouse on

# Prefix key
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Window and pane indexing
set -g base-index 1
set -g pane-base-index 1
set -g renumber-windows on

# Key bindings
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# Pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Pane resizing
bind H resize-pane -L 5
bind J resize-pane -D 5
bind K resize-pane -U 5
bind L resize-pane -R 5

# Reload config
bind r source-file /etc/tmux.conf \; display-message "Config reloaded!"

# Status bar
set -g status-position bottom
set -g status-bg black
set -g status-fg white
set -g status-left-length 20
set -g status-right-length 50
set -g status-left '#[fg=green]#S #[fg=white]| '
set -g status-right '#[fg=yellow]%Y-%m-%d #[fg=white]| #[fg=cyan]%H:%M'

# Window status
setw -g window-status-current-style 'fg=black bg=white bold'
setw -g window-status-current-format ' #I:#W#F '
setw -g window-status-style 'fg=white bg=black'
setw -g window-status-format ' #I:#W#F '

# Pane borders
set -g pane-border-style 'fg=colour8'
set -g pane-active-border-style 'fg=colour14'

# Message style
set -g message-style 'fg=black bg=yellow'
EOF

    echo -e "${GREEN}✓ Tmux configured${NC}"
}

# configure useful bash aliases
krun::optimize::system_performance::configure_bash_aliases() {
    echo -e "${BLUE}🔧 Configuring Bash aliases...${NC}"

    cat >/etc/profile.d/ops-aliases.sh <<'EOF'
# DevOps useful aliases

# System monitoring
alias cpu='top -o %CPU'
alias mem='top -o %MEM'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps aux'
alias pstree='pstree -p'

# Network
alias netstat='netstat -tuln'
alias ss='ss -tuln'
alias ports='netstat -tuln | grep LISTEN'
alias ping='ping -c 4'

# File operations
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias tree='tree -C'

# Log viewing
alias tailf='tail -f'
alias logs='journalctl -f'
alias syslog='tail -f /var/log/syslog'
alias messages='tail -f /var/log/messages'

# Process management
alias killall='killall -v'
alias pgrep='pgrep -l'

# Disk usage
alias ncdu='ncdu --color dark'
alias ducks='du -cks * | sort -rn | head -11'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gl='git log --oneline'
alias gp='git push'
alias gd='git diff'

# Docker shortcuts
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlogs='docker logs -f'

# System info
alias sysinfo='uname -a && cat /etc/os-release'
alias cpuinfo='cat /proc/cpuinfo'
alias meminfo='cat /proc/meminfo'

# File permissions
alias 644='chmod 644'
alias 755='chmod 755'
alias 777='chmod 777'

# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Service management
alias start='systemctl start'
alias stop='systemctl stop'
alias restart='systemctl restart'
alias status='systemctl status'
alias enable='systemctl enable'
alias disable='systemctl disable'

# JSON/YAML processing
alias json='jq .'
alias yaml='python3 -c "import sys, yaml, json; print(json.dumps(yaml.safe_load(sys.stdin), indent=2))"'

# Useful functions
weather() { curl -s "wttr.in/${1:-Shanghai}?format=3"; }
myip() { curl -s https://httpbin.org/ip | jq -r .origin; }
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
EOF

    chmod +x /etc/profile.d/ops-aliases.sh

    echo -e "${GREEN}✓ Bash aliases configured${NC}"
}

# run main
krun::optimize::system_performance::run "$@"
