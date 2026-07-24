#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/init_system.sh | bash
#
# system initialization (packages, tuning, limits)
# supported: Rocky 8/9, AlmaLinux 8/9, RHEL 8/9, CentOS Stream 8/9,
#            Debian 11/12, Ubuntu 22.04/24.04

# vars
SYSTEM_TIMEZONE="${SYSTEM_TIMEZONE:-Asia/Hong_Kong}"
SYSTEM_LOCALE="${SYSTEM_LOCALE:-en_US.UTF-8}"
DISABLE_SELINUX="${DISABLE_SELINUX:-1}"
DISTRO_ID=""
DISTRO_VERSION=""

# run code
krun::init::system::run() {
    [[ "$OSTYPE" != "darwin"* ]] && [[ $EUID -ne 0 ]] && echo "✗ must run as root" && exit 1

    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    krun::init::system::detect_distro
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code (Rocky / Alma / RHEL / CentOS Stream)
krun::init::system::centos() {
    echo "initializing ${DISTRO_ID:-rhel} ${DISTRO_VERSION}"
    krun::init::system::check_rhel_version
    krun::init::system::backup_configs
    krun::init::system::install_packages_rhel
    krun::init::system::common
}

# debian code (Debian / Ubuntu)
krun::init::system::debian() {
    echo "initializing ${DISTRO_ID:-debian} ${DISTRO_VERSION}"
    krun::init::system::check_debian_version
    krun::init::system::backup_configs
    krun::init::system::install_packages_debian
    krun::init::system::common
}

# mac code
krun::init::system::mac() {
    echo "✗ macOS not supported for system init"
    exit 1
}

krun::init::system::detect_distro() {
    [[ -f /etc/os-release ]] || return 0
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO_ID="${ID:-}"
    DISTRO_VERSION="${VERSION_ID:-}"
}

krun::init::system::check_rhel_version() {
    local major="${DISTRO_VERSION%%.*}"
    case "$major" in
    8 | 9) ;;
    7) echo "⚠ RHEL family 7 is EOL, some packages may be unavailable" ;;
    *) echo "⚠ untested RHEL family version: $DISTRO_VERSION" ;;
    esac
}

krun::init::system::check_debian_version() {
    case "${DISTRO_ID}:${DISTRO_VERSION}" in
    debian:11 | debian:12 | ubuntu:22.04 | ubuntu:24.04) ;;
    *) echo "⚠ untested Debian family version: ${DISTRO_ID} ${DISTRO_VERSION}" ;;
    esac
}

krun::init::system::pm() {
    command -v dnf >/dev/null 2>&1 && echo dnf && return
    echo yum
}

krun::init::system::pm_install() {
    local pm=$1
    shift
    $pm install -y "$@" || true
}

# common code
krun::init::system::common() {
    krun::init::system::configure_timezone
    krun::init::system::configure_locale
    krun::init::system::configure_sysctl
    krun::init::system::configure_limits
    krun::init::system::configure_network
    krun::init::system::configure_filesystem
    krun::init::system::configure_memory
    krun::init::system::configure_io
    krun::init::system::configure_selinux
    krun::init::system::configure_time_sync
    krun::init::system::configure_tuned
    krun::init::system::configure_cpufreq
    krun::init::system::configure_tools
    krun::init::system::disable_services
    sysctl -p /etc/sysctl.d/99-system.conf >/dev/null 2>&1 || true
    sysctl -p /etc/sysctl.d/99-docker.conf >/dev/null 2>&1 || true
    echo "✓ system init and performance tuning done, reboot recommended"
}

krun::init::system::backup_configs() {
    local existing_backup
    existing_backup=$(find /root -maxdepth 1 -name 'krun-backup-*' -type d 2>/dev/null | head -1)
    [[ -n "$existing_backup" ]] && return 0

    local backup_dir="/root/krun-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    local config
    for config in /etc/sysctl.conf /etc/security/limits.conf /etc/systemd/system.conf /etc/fstab; do
        [[ -f "$config" ]] && cp "$config" "$backup_dir/" 2>/dev/null || true
    done
    echo "✓ configs backed up to $backup_dir"
}

krun::init::system::install_packages_rhel() {
    echo "installing packages"
    local pm
    pm=$(krun::init::system::pm)
    $pm update -y
    krun::init::system::pm_install "$pm" epel-release
    krun::init::system::pm_install "$pm" \
        bash-completion vim-enhanced git tree lrzsz lsof net-tools \
        openssl openssl-devel wget curl rsync unzip zip \
        htop iotop sysstat tuned irqbalance numactl chrony \
        bind-utils telnet traceroute jq ncdu screen tmux \
        strace tcpdump nmap-ncat tar gzip bzip2 xz \
        psmisc procps-ng util-linux
    local optional=(ripgrep iftop nethogs mtr iperf3 glances parallel nmon dstat atop)
    local pkg
    for pkg in "${optional[@]}"; do
        krun::init::system::pm_install "$pm" "$pkg" >/dev/null 2>&1 || true
    done
    echo "✓ packages installed"
}

krun::init::system::install_packages_debian() {
    echo "installing packages"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get upgrade -y
    apt-get install -y \
        bash-completion vim git tree lrzsz lsof net-tools \
        openssl libssl-dev wget curl rsync unzip zip \
        htop iotop sysstat irqbalance numactl locales \
        dnsutils telnet traceroute jq ncdu screen tmux \
        strace tcpdump netcat-openbsd tar gzip bzip2 xz-utils \
        psmisc procps util-linux
    if [[ "${DISTRO_ID}" == "ubuntu" ]]; then
        apt-get install -y mtr-tiny linux-tools-common linux-tools-generic cpufrequtils >/dev/null 2>&1 || true
    else
        apt-get install -y mtr-tiny linux-cpupower >/dev/null 2>&1 || true
    fi
    apt-get install -y ripgrep iftop nethogs iperf3 glances parallel nmon dstat atop >/dev/null 2>&1 || true
    echo "✓ packages installed"
}

krun::init::system::configure_timezone() {
    echo "setting timezone to $SYSTEM_TIMEZONE"
    if command -v timedatectl >/dev/null 2>&1; then
        timedatectl set-timezone "$SYSTEM_TIMEZONE"
    elif [[ -f "/usr/share/zoneinfo/$SYSTEM_TIMEZONE" ]]; then
        ln -sf "/usr/share/zoneinfo/$SYSTEM_TIMEZONE" /etc/localtime
        echo "$SYSTEM_TIMEZONE" >/etc/timezone 2>/dev/null || true
    else
        echo "✗ timezone not found: $SYSTEM_TIMEZONE"
        return 1
    fi
    echo "✓ timezone set"
}

krun::init::system::configure_locale() {
    echo "setting locale to $SYSTEM_LOCALE"
    if command -v localectl >/dev/null 2>&1; then
        localectl set-locale "LANG=$SYSTEM_LOCALE" >/dev/null 2>&1 || true
    fi
    if [[ -f /etc/locale.conf ]]; then
        cat >/etc/locale.conf <<EOF
LANG=$SYSTEM_LOCALE
LC_ALL=$SYSTEM_LOCALE
EOF
    fi
    if [[ -f /etc/locale.gen ]] && grep -q "^# $SYSTEM_LOCALE UTF-8" /etc/locale.gen; then
        sed -i "s/^# $SYSTEM_LOCALE UTF-8/$SYSTEM_LOCALE UTF-8/" /etc/locale.gen
        locale-gen >/dev/null 2>&1 || true
    fi
    update-locale "LANG=$SYSTEM_LOCALE" >/dev/null 2>&1 || true
    echo "✓ locale set"
}

krun::init::system::configure_sysctl() {
    echo "writing sysctl tuning"
    cat >/etc/sysctl.d/99-system.conf <<'EOF'
# memory
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500
vm.overcommit_memory = 1
vm.overcommit_ratio = 50
vm.vfs_cache_pressure = 50
vm.min_free_kbytes = 65536

# network core
net.core.rmem_default = 262144
net.core.rmem_max = 67108864
net.core.wmem_default = 262144
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 5000
net.core.netdev_budget = 600
net.core.somaxconn = 65535
net.core.optmem_max = 81920

# tcp
net.ipv4.ip_local_port_range = 1024 65535
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
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_adv_win_scale = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_frto = 2
net.ipv4.tcp_no_metrics_save = 1

# ip security
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.ip_forward = 1

# docker / container host
fs.may_detach_mounts = 1
vm.max_map_count = 262144
kernel.keys.maxkeys = 2000000
kernel.keys.root_maxkeys = 2000000
fs.file-max = 2097152
fs.nr_open = 1048576
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 256

# kernel
kernel.pid_max = 4194304
kernel.threads-max = 2097152
kernel.panic = 10
kernel.hung_task_timeout_secs = 0
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1
kernel.unprivileged_bpf_disabled = 1
EOF

    cat >/etc/sysctl.d/99-docker.conf <<'EOF'
# Docker bridge networking (requires br_netfilter)
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1

# IPv6 container networks
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1
EOF

    mkdir -p /etc/modules-load.d
    echo br_netfilter >/etc/modules-load.d/br_netfilter.conf
    modprobe br_netfilter >/dev/null 2>&1 || true
    echo "✓ sysctl config written (system + docker, ip_forward=1)"
}

krun::init::system::configure_limits() {
    echo "writing limits"
    cat >/etc/security/limits.d/99-system.conf <<'EOF'
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 1048576
* hard nproc 1048576
* soft memlock unlimited
* hard memlock unlimited
root soft nofile 1048576
root hard nofile 1048576
root soft nproc 1048576
root hard nproc 1048576
root soft memlock unlimited
root hard memlock unlimited
EOF

    if [[ -f /etc/systemd/system.conf ]]; then
        sed -i 's/^#\?DefaultLimitNOFILE=.*/DefaultLimitNOFILE=1048576/' /etc/systemd/system.conf
        sed -i 's/^#\?DefaultLimitNPROC=.*/DefaultLimitNPROC=1048576/' /etc/systemd/system.conf
        sed -i 's/^#\?DefaultLimitMEMLOCK=.*/DefaultLimitMEMLOCK=infinity/' /etc/systemd/system.conf
        systemctl daemon-reload >/dev/null 2>&1 || true
    fi
    echo "✓ limits config written"
}

krun::init::system::configure_network() {
    [[ -f /proc/sys/net/core/rmem_max ]] && echo 67108864 >/proc/sys/net/core/rmem_max
    [[ -f /proc/sys/net/core/wmem_max ]] && echo 67108864 >/proc/sys/net/core/wmem_max
    if lsmod | grep -q tcp_bbr || modprobe tcp_bbr >/dev/null 2>&1; then
        [[ ! -f /etc/modules-load.d/bbr.conf ]] && echo "tcp_bbr" >/etc/modules-load.d/bbr.conf
        echo "✓ BBR enabled"
    else
        echo "⚠ BBR module not available, skip"
    fi
}

krun::init::system::configure_filesystem() {
    if [[ -f /etc/fstab ]] && ! grep -q noatime /etc/fstab; then
        cp /etc/fstab "/etc/fstab.bak.$(date +%Y%m%d)" 2>/dev/null || true
        sed -i 's/\(.*ext[234].*\)defaults\(.*\)/\1defaults,noatime,nodiratime\2/' /etc/fstab
        sed -i 's/\(.*xfs.*\)defaults\(.*\)/\1defaults,noatime,nodiratime\2/' /etc/fstab
        echo "✓ fstab noatime applied"
    fi
    if command -v blockdev >/dev/null 2>&1; then
        local device
        for device in $(lsblk -nd -o NAME 2>/dev/null | grep -E '^(sd|nvme|vd)'); do
            blockdev --setra 4096 "/dev/$device" >/dev/null 2>&1 || true
        done
    fi
}

krun::init::system::configure_memory() {
    if [[ ! -f /sys/kernel/mm/transparent_hugepage/enabled ]]; then
        return 0
    fi
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
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/defrag'

[Install]
WantedBy=basic.target
EOF
    fi
    systemctl enable disable-thp.service >/dev/null 2>&1 || true
    [[ -f /proc/sys/kernel/numa_balancing ]] && echo 1 >/proc/sys/kernel/numa_balancing
    echo "✓ memory tuning applied"
}

krun::init::system::configure_io() {
    local device sched
    for device in $(lsblk -nd -o NAME,ROTA 2>/dev/null | awk '$2==0 {print $1}'); do
        sched="/sys/block/$device/queue/scheduler"
        [[ -f "$sched" ]] || continue
        grep -q mq-deadline "$sched" && echo mq-deadline >"$sched" && continue
        grep -q none "$sched" && echo none >"$sched" && continue
        grep -q noop "$sched" && echo noop >"$sched" && continue
    done
    cat >/etc/udev/rules.d/60-ioschedulers.rules <<'EOF'
ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]n[0-9]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
EOF
    echo "✓ io scheduler configured"
}

krun::init::system::configure_selinux() {
    [[ "$DISABLE_SELINUX" != "1" ]] && return 0
    [[ ! -f /etc/selinux/config ]] && return 0
    echo "disabling SELinux"
    sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
    setenforce 0 >/dev/null 2>&1 || true
    echo "✓ SELinux disabled"
}

krun::init::system::configure_time_sync() {
    # Prefer each distro's current time sync daemon; retire legacy ntpd.
    echo "configuring time sync"
    local units
    units=$(systemctl list-unit-files 2>/dev/null || true)

    local svc
    for svc in ntpd ntp openntpd; do
        if echo "$units" | grep -q "^${svc}\.service"; then
            echo "  retiring legacy ${svc}"
            systemctl stop "$svc" >/dev/null 2>&1 || true
            systemctl disable "$svc" >/dev/null 2>&1 || true
            systemctl mask "$svc" >/dev/null 2>&1 || true
        fi
    done

    if command -v yum >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
        # RHEL/Rocky/Alma: chronyd
        if echo "$units" | grep -q '^systemd-timesyncd\.service'; then
            systemctl stop systemd-timesyncd >/dev/null 2>&1 || true
            systemctl disable systemd-timesyncd >/dev/null 2>&1 || true
            systemctl mask systemd-timesyncd >/dev/null 2>&1 || true
        fi
        if ! echo "$units" | grep -q '^chronyd\.service'; then
            echo "⚠ chronyd not installed, skip time sync"
            return 0
        fi
        systemctl unmask chronyd >/dev/null 2>&1 || true
        systemctl enable --now chronyd >/dev/null 2>&1 || true
        command -v timedatectl >/dev/null 2>&1 && timedatectl set-ntp true >/dev/null 2>&1 || true
        echo "✓ chronyd enabled (RHEL family default)"
        return 0
    fi

    if command -v apt-get >/dev/null 2>&1; then
        # Debian/Ubuntu: systemd-timesyncd
        if echo "$units" | grep -q '^chronyd\.service'; then
            systemctl stop chronyd >/dev/null 2>&1 || true
            systemctl disable chronyd >/dev/null 2>&1 || true
            systemctl mask chronyd >/dev/null 2>&1 || true
        fi
        if ! echo "$units" | grep -q '^systemd-timesyncd\.service'; then
            echo "⚠ systemd-timesyncd not found, skip time sync"
            return 0
        fi
        systemctl unmask systemd-timesyncd >/dev/null 2>&1 || true
        systemctl enable --now systemd-timesyncd >/dev/null 2>&1 || true
        command -v timedatectl >/dev/null 2>&1 && timedatectl set-ntp true >/dev/null 2>&1 || true
        echo "✓ systemd-timesyncd enabled (Debian/Ubuntu default)"
        return 0
    fi

    echo "⚠ unsupported platform for time sync, skip"
}

krun::init::system::configure_tuned() {
    command -v tuned-adm >/dev/null 2>&1 || return 0
    systemctl enable --now tuned >/dev/null 2>&1 || true
    tuned-adm profile throughput-performance >/dev/null 2>&1 || true
    echo "✓ tuned throughput profile enabled"
}

krun::init::system::configure_cpufreq() {
    [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]] || return 0
    local cpu
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo performance >"$cpu" 2>/dev/null || true
    done
    [[ -d /etc/default ]] && echo 'GOVERNOR="performance"' >/etc/default/cpufrequtils 2>/dev/null || true
    echo "✓ cpufreq governor set to performance"
}

krun::init::system::configure_tools() {
    grep -q 'set paste' /etc/vimrc 2>/dev/null || echo 'set paste' >>/etc/vimrc
    mkdir -p /etc/vim
    cat >/etc/vim/vimrc.local <<'EOF'
set nocompatible
set encoding=utf-8
set number
set tabstop=4
set shiftwidth=4
set expandtab
set hlsearch
set incsearch
syntax enable
EOF
    [[ ! -f /root/.vimrc ]] && echo 'source /etc/vim/vimrc.local' >/root/.vimrc

    git config --global init.defaultBranch main >/dev/null 2>&1 || true
    git config --global core.editor vim >/dev/null 2>&1 || true
    git config --global color.ui auto >/dev/null 2>&1 || true

    cat >/etc/tmux.conf <<'EOF'
set -g default-terminal "screen-256color"
set -g history-limit 10000
set -g mouse on
set -g base-index 1
set -g pane-base-index 1
EOF

    cat >/etc/profile.d/ops-aliases.sh <<'EOF'
alias ll='ls -alF'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias grep='grep --color=auto'
alias start='systemctl start'
alias stop='systemctl stop'
alias restart='systemctl restart'
alias status='systemctl status'
EOF
    chmod +x /etc/profile.d/ops-aliases.sh
    echo "✓ dev/ops tools configured"
}

krun::init::system::disable_services() {
    local services=(bluetooth cups avahi-daemon ModemManager whoopsie apport)
    local service
    for service in "${services[@]}"; do
        systemctl disable "$service" >/dev/null 2>&1 || true
        systemctl stop "$service" >/dev/null 2>&1 || true
    done
    systemctl enable --now irqbalance >/dev/null 2>&1 || true
    echo "✓ unnecessary services disabled"
}

# run main
krun::init::system::run "$@"
