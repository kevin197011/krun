#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-rocky-repo.sh | bash

# vars

# run code
krun::config::rocky_repo::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::rocky_repo::centos() {
    [[ "$OSTYPE" != "darwin"* ]] && [[ $EUID -ne 0 ]] && echo "✗ Please run as root" && exit 1

    echo "Configuring Rocky Linux repositories..."

    mkdir -p /etc/yum.repos.d/backup
    ls /etc/yum.repos.d/rocky*.repo >/dev/null 2>&1 && mv /etc/yum.repos.d/rocky*.repo /etc/yum.repos.d/backup/ || true

    cat >/etc/yum.repos.d/rocky.repo <<'EOF'
[baseos]
name=Rocky Linux $releasever - BaseOS
baseurl=http://mirrors.tuna.tsinghua.edu.cn/rocky/$releasever/BaseOS/$basearch/os/
enabled=1
gpgcheck=0

[appstream]
name=Rocky Linux $releasever - AppStream
baseurl=http://mirrors.tuna.tsinghua.edu.cn/rocky/$releasever/AppStream/$basearch/os/
enabled=1
gpgcheck=0

[extras]
name=Rocky Linux $releasever - Extras
baseurl=http://mirrors.tuna.tsinghua.edu.cn/rocky/$releasever/extras/$basearch/os/
enabled=1
gpgcheck=0
EOF

    if command -v dnf >/dev/null 2>&1; then
        dnf clean all >/dev/null 2>&1
        dnf makecache >/dev/null 2>&1
    else
        yum clean all >/dev/null 2>&1
        yum makecache >/dev/null 2>&1
    fi

    krun::config::rocky_repo::common
}

# debian code
krun::config::rocky_repo::debian() {
    echo "This script is for Rocky Linux/CentOS systems only"
    exit 1
}

# mac code
krun::config::rocky_repo::mac() {
    echo "This script is for Rocky Linux/CentOS systems only"
    exit 1
}

# common code
krun::config::rocky_repo::common() {
    echo "Rocky Linux repository configuration completed"
}

# run main
krun::config::rocky_repo::run "$@"
