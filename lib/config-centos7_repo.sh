#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-centos7_repo.sh | bash

# vars

# run code
krun::config::centos7_repo::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::centos7_repo::centos() {
    krun::config::centos7_repo::common

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
EOF

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
