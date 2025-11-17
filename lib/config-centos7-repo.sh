#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-centos7-repo.sh | bash

# vars

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
    krun::config::centos7_repo::common

    os_version=$(cat /etc/os-release 2>/dev/null | grep -E '^PRETTY_NAME=')

    if ! echo "$os_version" | grep -Eq "CentOS Linux 7|Red Hat Enterprise Linux 7|Rocky Linux 7"; then
        echo "Not CentOS/RHEL/Rocky 7, skip..."
        return 0
    fi

    # delete old
    rm -rf /etc/yum.repos.d/*

    # config repo
    tee /etc/yum.repos.d/devops.repo <<EOF
[atomic]
name=CentOS-\$releasever - atomic
baseurl=https://vault.centos.org/centos/\$releasever/atomic/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[centosplus]
name=CentOS-\$releasever - centosplus
baseurl=https://vault.centos.org/centos/\$releasever/centosplus/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[dotnet]
name=CentOS-\$releasever - dotnet
baseurl=https://vault.centos.org/centos/\$releasever/dotnet/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[extras]
name=CentOS-\$releasever - extras
baseurl=https://vault.centos.org/centos/\$releasever/extras/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[fasttrack]
name=CentOS-\$releasever - fasttrack
baseurl=https://vault.centos.org/centos/\$releasever/fasttrack/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[os]
name=CentOS-\$releasever - os
baseurl=https://vault.centos.org/centos/\$releasever/os/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[rt]
name=CentOS-\$releasever - rt
baseurl=https://vault.centos.org/centos/\$releasever/rt/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[updates]
name=CentOS-\$releasever - updates
baseurl=https://vault.centos.org/centos/\$releasever/updates/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=1

[epel]
name=Extra Packages for Enterprise Linux 7 - \$basearch
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place its address here.
#baseurl=http://download.example/pub/epel/7/\$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=\$basearch&infra=\$infra&content=\$contentdir
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

[epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - \$basearch - Debug
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place its address here.
#baseurl=http://download.example/pub/epel/7/\$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-7&arch=\$basearch&infra=\$infra&content=\$contentdir
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux 7 - \$basearch - Source
# It is much more secure to use the metalink, but if you wish to use a local mirror
# place it's address here.
#baseurl=http://download.example/pub/epel/7/source/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=\$basearch&infra=\$infra&content=\$contentdir
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1
EOF
    yum install https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm -y
    yum clean all
    yum makecache fast
}

# debian code
krun::config::centos7_repo::debian() {
    krun::config::centos7_repo::common
}

# mac code
krun::config::centos7_repo::mac() {
    krun::config::centos7_repo::common
}

# common code
krun::config::centos7_repo::common() {
    echo "${FUNCNAME}"
}

# run main
krun::config::centos7_repo::run "$@"
