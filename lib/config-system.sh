#!/usr/bin/env bash

# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::config::system::run() {
    # default debian platform
    platform='debian'

    command -v yum >/dev/null && platform='centos'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::system::centos() {
    yum install -y epel-release
    yum install -y bash-completion bash-completion-extras
    timedatectl set-timezone Asia/Hong_Kong
    yum upgrade -y
    yum update -y
    yum install -y ncdu vim openssl openssl-devel
    yum-config-manager --add-repo=https://copr.fedorainfracloud.org/coprs/carlwgeorge/ripgrep/repo/epel-7/carlwgeorge-ripgrep-epel-7.repo
    yum install -y ripgrep
    yum install lrzsz -y
    yum install -y epel-release \
        centos-release-scl-rh \
        centos-release-scl

    tee /etc/sysctl.conf >/dev/null <<EOF
vm.overcommit_memory=1
net.ipv4.ip_local_port_range = 1024 65535
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 256960
net.core.wmem_default = 256960
net.core.netdev_max_backlog = 20000
net.core.somaxconn = 65535
net.core.optmem_max = 81920
net.ipv4.tcp_mem = 131072  262144  524288
net.ipv4.tcp_rmem = 8760  256960  16777216
net.ipv4.tcp_wmem = 8760  256960  16777216
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 30
fs.file-max = 265535
net.ipv4.tcp_max_tw_buckets = 50000
net.ipv4.tcp_max_syn_backlog = 20000

EOF

    tee /etc/security/limits.conf >/dev/null <<EOF
*    soft nproc 65535
*    hard nproc 65535
*    soft nofile 65535
*    hard nofile 65535

EOF

    sysctl -p
    perl -pi -e 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    grep -q 'set paste' /etc/vimrc || echo 'set paste' >>/etc/vimrc
    echo "config finish, please reboot host!"
    # reboot
}

# debian code
krun::config::system::debian() {
    echo 'debian todo...'
}

# run main
krun::config::system::run "$@"
