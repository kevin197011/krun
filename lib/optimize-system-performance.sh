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

# run code
krun::optimize::system_performance::run() {
    [[ "$OSTYPE" != "darwin"* ]] && [[ $EUID -ne 0 ]] && echo "✗ Please run as root" && exit 1

    echo "Starting system performance optimization..."

    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'

    krun::optimize::system_performance::backup_configs
    eval "${FUNCNAME/::run/::${platform}}"
    krun::optimize::system_performance::common
    krun::optimize::system_performance::configure_tools

    echo "System performance optimization completed"
    echo "Please reboot the system to apply all changes"
}

# centos code
krun::optimize::system_performance::centos() {
    echo "Applying CentOS/RHEL optimizations..."

    dnf update -y >/dev/null 2>&1 || yum update -y >/dev/null 2>&1
    dnf install -y epel-release >/dev/null 2>&1 || yum install -y epel-release >/dev/null 2>&1
    dnf install -y \
        htop iotop sysstat tuned irqbalance numactl bash-completion \
        vim vim-enhanced curl wget rsync lsof strace tcpdump \
        nmap-ncat bind-utils git tree unzip zip screen tmux \
        net-tools telnet traceroute mtr iperf3 jq ncdu \
        tar gzip bzip2 xz which nano less grep sed awk find \
        psmisc procps-ng util-linux coreutils iftop nethogs \
        nmon dstat atop glances multitail parallel >/dev/null 2>&1 ||
        yum install -y \
            htop iotop sysstat tuned irqbalance numactl bash-completion \
            vim vim-enhanced curl wget rsync lsof strace tcpdump \
            nmap-ncat bind-utils git tree unzip zip screen tmux \
            net-tools telnet traceroute mtr iperf3 jq ncdu \
            tar gzip bzip2 xz which nano less grep sed gawk \
            findutils psmisc procps-ng util-linux coreutils iftop \
            nethogs nmon dstat atop glances multitail parallel >/dev/null 2>&1

    systemctl enable --now tuned >/dev/null 2>&1 || true
    systemctl enable --now irqbalance >/dev/null 2>&1 || true
    tuned-adm profile throughput-performance >/dev/null 2>&1 || true

    local services_to_disable=("bluetooth.service" "cups.service" "avahi-daemon.service" "ModemManager.service")
    for service in "${services_to_disable[@]}"; do
        systemctl disable "$service" >/dev/null 2>&1 || true
    done

    if [[ -f /etc/selinux/config ]]; then
        sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
        setenforce 0 >/dev/null 2>&1 || true
    fi
}

# debian code
krun::optimize::system_performance::debian() {
    echo "Applying Debian/Ubuntu optimizations..."

    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        htop iotop sysstat irqbalance numactl bash-completion \
        vim vim-nox curl wget rsync lsof strace tcpdump \
        netcat-openbsd dnsutils cpufrequtils linux-tools-common \
        linux-tools-generic git tree unzip zip screen tmux \
        net-tools telnet traceroute mtr-tiny iperf3 jq ncdu \
        tar gzip bzip2 xz-utils nano less grep sed gawk \
        findutils psmisc procps util-linux coreutils iftop \
        nethogs nmon dstat atop glances multitail parallel >/dev/null 2>&1

    systemctl enable --now irqbalance >/dev/null 2>&1 || true

    if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]; then
        echo 'performance' | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null || true
        echo 'GOVERNOR="performance"' >/etc/default/cpufrequtils
    fi

    local services_to_disable=("bluetooth.service" "cups.service" "avahi-daemon.service" "ModemManager.service" "whoopsie.service" "apport.service")
    for service in "${services_to_disable[@]}"; do
        systemctl disable "$service" >/dev/null 2>&1 || true
    done
}

# mac code
krun::optimize::system_performance::mac() {
    echo "macOS optimizations are limited"
    command -v brew >/dev/null || {
        echo "✗ Homebrew is required"
        exit 1
    }
}

# common code
krun::optimize::system_performance::common() {
    echo "Applying common optimizations..."

    krun::optimize::system_performance::configure_sysctl
    krun::optimize::system_performance::configure_limits
    krun::optimize::system_performance::optimize_network
    krun::optimize::system_performance::optimize_filesystem
    krun::optimize::system_performance::optimize_memory
    krun::optimize::system_performance::optimize_io

    if command -v timedatectl >/dev/null 2>&1; then
        timedatectl set-timezone Asia/Shanghai >/dev/null 2>&1 || true
    elif [[ -f /usr/share/zoneinfo/Asia/Shanghai ]]; then
        ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
        echo 'Asia/Shanghai' >/etc/timezone 2>/dev/null || true
    fi

    if systemctl list-unit-files | grep -q systemd-timesyncd; then
        systemctl enable --now systemd-timesyncd >/dev/null 2>&1 || true
    elif systemctl list-unit-files | grep -q chronyd; then
        systemctl enable --now chronyd >/dev/null 2>&1 || true
    elif systemctl list-unit-files | grep -q ntpd; then
        systemctl enable --now ntpd >/dev/null 2>&1 || true
    fi

    sysctl -p /etc/sysctl.d/99-performance.conf >/dev/null 2>&1 || true
}

# backup original configurations
krun::optimize::system_performance::backup_configs() {
    local existing_backup
    existing_backup=$(find /root -maxdepth 1 -name "krun-backup-*" -type d | head -1)
    [[ -n "$existing_backup" ]] && return

    local backup_dir="/root/krun-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    local configs_to_backup=("/etc/sysctl.conf" "/etc/security/limits.conf" "/etc/systemd/system.conf" "/etc/fstab")
    for config in "${configs_to_backup[@]}"; do
        [[ -f "$config" ]] && cp "$config" "$backup_dir/" 2>/dev/null || true
    done
}

# configure kernel parameters
krun::optimize::system_performance::configure_sysctl() {
    cat >/etc/sysctl.d/99-performance.conf <<'EOF'
# Kernel performance optimizations
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
}

# configure system limits
krun::optimize::system_performance::configure_limits() {
    cat >/etc/security/limits.d/99-performance.conf <<'EOF'
# System performance limits
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 1048576
* hard nproc 1048576
* soft memlock unlimited
* hard memlock unlimited
* soft stack 8192
* hard stack 8192
root soft nofile 1048576
root hard nofile 1048576
root soft nproc 1048576
root hard nproc 1048576
root soft memlock unlimited
root hard memlock unlimited
EOF

    if [[ -f /etc/systemd/system.conf ]]; then
        sed -i 's/#DefaultLimitNOFILE=.*/DefaultLimitNOFILE=1048576/' /etc/systemd/system.conf
        sed -i 's/^DefaultLimitNOFILE=.*/DefaultLimitNOFILE=1048576/' /etc/systemd/system.conf
        sed -i 's/#DefaultLimitNPROC=.*/DefaultLimitNPROC=1048576/' /etc/systemd/system.conf
        sed -i 's/^DefaultLimitNPROC=.*/DefaultLimitNPROC=1048576/' /etc/systemd/system.conf
        sed -i 's/#DefaultLimitMEMLOCK=.*/DefaultLimitMEMLOCK=infinity/' /etc/systemd/system.conf
        sed -i 's/^DefaultLimitMEMLOCK=.*/DefaultLimitMEMLOCK=infinity/' /etc/systemd/system.conf
        systemctl daemon-reload >/dev/null 2>&1 || true
    fi
}

# optimize network settings
krun::optimize::system_performance::optimize_network() {
    [[ -f /proc/sys/net/core/rmem_max ]] && echo 67108864 >/proc/sys/net/core/rmem_max
    [[ -f /proc/sys/net/core/wmem_max ]] && echo 67108864 >/proc/sys/net/core/wmem_max

    if lsmod | grep -q tcp_bbr || modprobe tcp_bbr >/dev/null 2>&1; then
        [[ ! -f /etc/modules-load.d/bbr.conf ]] && echo "tcp_bbr" >/etc/modules-load.d/bbr.conf
    fi
}

# optimize filesystem settings
krun::optimize::system_performance::optimize_filesystem() {
    if [[ -f /etc/fstab ]] && ! grep -q "noatime" /etc/fstab; then
        [[ ! -f /etc/fstab.bak.* ]] && cp /etc/fstab /etc/fstab.bak.$(date +%Y%m%d)
        sed -i 's/\(.*ext[234].*\)defaults\(.*\)/\1defaults,noatime,nodiratime\2/' /etc/fstab
        sed -i 's/\(.*xfs.*\)defaults\(.*\)/\1defaults,noatime,nodiratime\2/' /etc/fstab
    fi

    if command -v blockdev >/dev/null 2>&1; then
        for device in $(lsblk -nd -o NAME | grep -E '^(sd|nvme|vd)'); do
            blockdev --setra 4096 "/dev/$device" >/dev/null 2>&1 || true
        done
    fi
}

# optimize memory management
krun::optimize::system_performance::optimize_memory() {
    if [[ -f /sys/kernel/mm/transparent_hugepage/enabled ]]; then
        echo never >/sys/kernel/mm/transparent_hugepage/enabled
        echo never >/sys/kernel/mm/transparent_hugepage/defrag

        if [[ ! -f /etc/systemd/system/disable-thp.service ]]; then
            cat >/etc/systemd/system/disable-thp.service <<'EOF'
[Unit]
Description=Disable Transparent Huge Pages
DefaultDependencies=false
After=sysinit.target local-fs.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo never | tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null'
ExecStart=/bin/sh -c 'echo never | tee /sys/kernel/mm/transparent_hugepage/defrag > /dev/null'

[Install]
WantedBy=basic.target
EOF
        fi
        systemctl enable disable-thp.service >/dev/null 2>&1 || true
    fi

    [[ -f /proc/sys/kernel/numa_balancing ]] && echo 1 >/proc/sys/kernel/numa_balancing
}

# optimize I/O scheduler
krun::optimize::system_performance::optimize_io() {
    for device in $(lsblk -nd -o NAME,ROTA | awk '$2==0 {print $1}'); do
        if [[ -f "/sys/block/$device/queue/scheduler" ]]; then
            if grep -q "mq-deadline" "/sys/block/$device/queue/scheduler"; then
                echo "mq-deadline" >"/sys/block/$device/queue/scheduler"
            elif grep -q "deadline" "/sys/block/$device/queue/scheduler"; then
                echo "deadline" >"/sys/block/$device/queue/scheduler"
            elif grep -q "noop" "/sys/block/$device/queue/scheduler"; then
                echo "noop" >"/sys/block/$device/queue/scheduler"
            fi
        fi
    done

    for device in $(lsblk -nd -o NAME,ROTA | awk '$2==1 {print $1}'); do
        if [[ -f "/sys/block/$device/queue/scheduler" ]]; then
            if grep -q "cfq" "/sys/block/$device/queue/scheduler"; then
                echo "cfq" >"/sys/block/$device/queue/scheduler"
            elif grep -q "bfq" "/sys/block/$device/queue/scheduler"; then
                echo "bfq" >"/sys/block/$device/queue/scheduler"
            fi
        fi
    done

    cat >/etc/udev/rules.d/60-ioschedulers.rules <<'EOF'
ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]n[0-9]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="cfq"
EOF
}

# configure development and ops tools
krun::optimize::system_performance::configure_tools() {
    krun::optimize::system_performance::configure_vim
    krun::optimize::system_performance::configure_git
    krun::optimize::system_performance::configure_tmux
    krun::optimize::system_performance::configure_bash_aliases
}

# configure vim
krun::optimize::system_performance::configure_vim() {
    mkdir -p /etc/vim
    cat >/etc/vim/vimrc.local <<'EOF'
set nocompatible
set encoding=utf-8
set number
set ruler
set showcmd
set wildmenu
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
set hlsearch
set incsearch
set ignorecase
set smartcase
set nobackup
set noswapfile
syntax enable
set background=dark
EOF

    [[ ! -f /root/.vimrc ]] && echo 'source /etc/vim/vimrc.local' >/root/.vimrc
}

# configure git
krun::optimize::system_performance::configure_git() {
    git config --global init.defaultBranch main >/dev/null 2>&1 || true
    git config --global core.editor vim >/dev/null 2>&1 || true
    git config --global color.ui auto >/dev/null 2>&1 || true
    git config --global alias.st status >/dev/null 2>&1 || true
    git config --global alias.co checkout >/dev/null 2>&1 || true
    git config --global alias.br branch >/dev/null 2>&1 || true
    git config --global alias.ci commit >/dev/null 2>&1 || true
}

# configure tmux
krun::optimize::system_performance::configure_tmux() {
    cat >/etc/tmux.conf <<'EOF'
set -g default-terminal "screen-256color"
set -g history-limit 10000
set -g mouse on
unbind C-b
set -g prefix C-a
bind C-a send-prefix
set -g base-index 1
set -g pane-base-index 1
bind | split-window -h
bind - split-window -v
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
bind r source-file /etc/tmux.conf \; display-message "Config reloaded!"
set -g status-position bottom
set -g status-left '#S | '
set -g status-right '%Y-%m-%d | %H:%M'
EOF
}

# configure bash aliases
krun::optimize::system_performance::configure_bash_aliases() {
    cat >/etc/profile.d/ops-aliases.sh <<'EOF'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps aux'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias start='systemctl start'
alias stop='systemctl stop'
alias restart='systemctl restart'
alias status='systemctl status'
EOF
    chmod +x /etc/profile.d/ops-aliases.sh
}

# run main
krun::optimize::system_performance::run "$@"
