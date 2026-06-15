#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-centos7-repo.sh | sudo bash
#
# Idempotent: safe to re-run. Overwrites devops.repo, prunes conflicting legacy repos,
# installs endpoint-repo only when missing, then refreshes YUM cache.

# vars
centos7_endpoint_rpm=${centos7_endpoint_rpm:-https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm}

# run code
krun::config::centos7_repo::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::centos7_repo::centos() {
    [[ "$(id -u)" -eq 0 ]] || {
        echo "✗ Run as root or with sudo"
        return 1
    }

    local os_version
    os_version=$(grep -E '^PRETTY_NAME=' /etc/os-release 2>/dev/null || true)

    if ! echo "$os_version" | grep -Eq "CentOS Linux 7|Red Hat Enterprise Linux 7|Rocky Linux 7"; then
        echo "Not CentOS/RHEL/Rocky 7, skip..."
        return 0
    fi

    krun::config::centos7_repo::write_devops_repo
    krun::config::centos7_repo::prune_legacy_repos
    krun::config::centos7_repo::install_endpoint_repo
    krun::config::centos7_repo::refresh_yum_cache

    echo "✓ CentOS 7 repo configuration complete"
}

krun::config::centos7_repo::write_devops_repo() {
    mkdir -p /etc/yum.repos.d
    tee /etc/yum.repos.d/devops.repo >/dev/null <<'EOF'
[atomic]
name=CentOS-$releasever - atomic
baseurl=https://vault.centos.org/centos/$releasever/atomic/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[centosplus]
name=CentOS-$releasever - centosplus
baseurl=https://vault.centos.org/centos/$releasever/centosplus/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[dotnet]
name=CentOS-$releasever - dotnet
baseurl=https://vault.centos.org/centos/$releasever/dotnet/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[extras]
name=CentOS-$releasever - extras
baseurl=https://vault.centos.org/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[fasttrack]
name=CentOS-$releasever - fasttrack
baseurl=https://vault.centos.org/centos/$releasever/fasttrack/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[os]
name=CentOS-$releasever - os
baseurl=https://vault.centos.org/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[rt]
name=CentOS-$releasever - rt
baseurl=https://vault.centos.org/centos/$releasever/rt/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[updates]
name=CentOS-$releasever - updates
baseurl=https://vault.centos.org/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[epel]
name=Extra Packages for Enterprise Linux 7 - $basearch
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place its address here.
#baseurl=http://download.example/pub/epel/7/$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch&infra=$infra&content=$contentdir
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

[epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - $basearch - Debug
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place its address here.
#baseurl=http://download.example/pub/epel/7/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-7&arch=$basearch&infra=$infra&content=$contentdir
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux 7 - $basearch - Source
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place it's address here.
#baseurl=http://download.example/pub/epel/7/source/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=$basearch&infra=$infra&content=$contentdir
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1
EOF
    echo "✓ Wrote /etc/yum.repos.d/devops.repo"
}

# Remove third-party / legacy repos; keep devops.repo and endpoint-* repos we manage.
krun::config::centos7_repo::prune_legacy_repos() {
    local f base removed=0

    shopt -s nullglob
    for f in /etc/yum.repos.d/*.repo /etc/yum.repos.d/*.repo.rpmnew \
        /etc/yum.repos.d/*.repo.rpmsave /etc/yum.repos.d/*.repo.orig; do
        [[ -f "$f" ]] || continue
        base=$(basename "$f")
        case "$base" in
            devops.repo) continue ;;
            endpoint*.repo) continue ;;
        esac
        rm -f "$f"
        echo "Removed: ${base}"
        removed=1
    done
    shopt -u nullglob

    [[ "$removed" -eq 0 ]] && echo "✓ No conflicting repo files to remove"
}

krun::config::centos7_repo::install_endpoint_repo() {
    if rpm -q endpoint-repo >/dev/null 2>&1; then
        echo "✓ endpoint-repo already installed, skipping"
        return 0
    fi

    echo "Installing endpoint-repo..."
    yum install -y "$centos7_endpoint_rpm"
    echo "✓ endpoint-repo installed"
}

krun::config::centos7_repo::refresh_yum_cache() {
    yum clean all
    yum makecache fast
    echo "✓ YUM cache refreshed"
}

# debian code
krun::config::centos7_repo::debian() {
    echo "✗ This script only supports CentOS/RHEL/Rocky 7"
    return 1
}

# mac code
krun::config::centos7_repo::mac() {
    echo "✗ This script only supports CentOS/RHEL/Rocky 7"
    return 1
}

# run main
krun::config::centos7_repo::run "$@"
