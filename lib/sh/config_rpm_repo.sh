#!/usr/bin/env bash
# Copyright (c) 2026 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_rpm_repo.sh | sudo bash
#
# Vars:
#   REPO=rocky|centos7   (default: rocky)

# vars
REPO="${REPO:-rocky}"

# run code
krun::config::rpm_repo::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

krun::config::rpm_repo::centos() {
    [[ $EUID -eq 0 ]] || {
        echo "✗ Please run as root"
        exit 1
    }

    case "$REPO" in
    rocky | centos7) ;;
    *)
        echo "✗ REPO must be rocky or centos7 (got: $REPO)"
        exit 1
        ;;
    esac

    mkdir -p /etc/yum.repos.d/backup

    if [[ "$REPO" == "rocky" ]]; then
        mv /etc/yum.repos.d/rocky*.repo /etc/yum.repos.d/backup/ 2>/dev/null || true
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
    else
        mv /etc/yum.repos.d/centos7.repo /etc/yum.repos.d/backup/ 2>/dev/null || true
        cat >/etc/yum.repos.d/centos7.repo <<'EOF'
[base]
name=CentOS-7 - Base
baseurl=http://mirrors.tuna.tsinghua.edu.cn/centos/7/os/$basearch/
gpgcheck=0
enabled=1

[updates]
name=CentOS-7 - Updates
baseurl=http://mirrors.tuna.tsinghua.edu.cn/centos/7/updates/$basearch/
gpgcheck=0
enabled=1

[extras]
name=CentOS-7 - Extras
baseurl=http://mirrors.tuna.tsinghua.edu.cn/centos/7/extras/$basearch/
gpgcheck=0
enabled=1
EOF
    fi

    if command -v dnf >/dev/null 2>&1; then
        dnf clean all
        dnf makecache
    else
        yum clean all
        yum makecache
    fi

    echo "✓ ${REPO} repo configured"
}

krun::config::rpm_repo::debian() {
    echo "✗ rpm repo config is for RHEL family only"
    exit 1
}

krun::config::rpm_repo::mac() {
    echo "✗ rpm repo config is for RHEL family only"
    exit 1
}

# run main
krun::config::rpm_repo::run "$@"
