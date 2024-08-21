#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-lsyncd.sh | bash

# vars

# run code
krun::install::lsyncd::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::lsyncd::centos() {
    krun::install::lsyncd::common
    yum install -y lsyncd
    tee /etc/lsyncd.conf <<EOF
settings {
    logfile = "/var/log/lsyncd/lsyncd.log",
    statusFile = "/var/log/lsyncd/lsyncd.status",
    nodaemon = false
}

-- rsync /data/dir1
sync {
    default.rsyncssh,
    source = "/data/dir1/",
    host = "10.1.1.1", 
    targetdir = "/data/dir1/",
    delete = true,
    rsync = {
        archive = true,
        compress = true,
        verbose = true,
        rsh = "/usr/bin/ssh -p 22 -o StrictHostKeyChecking=no"
    }
}

-- rsync /data/dir2
sync {
    default.rsyncssh,
    source = "/data/dir2/",
    host = "10.1.1.2", 
    targetdir = "/data/dir2/",
    delete = true,
    rsync = {
        archive = true,
        compress = true,
        verbose = true,
        rsh = "/usr/bin/ssh -p 22 -o StrictHostKeyChecking=no"
    }
}

-- rsync /data/dir3
sync {
    default.rsyncssh,
    source = "/data/dir3/",
    host = "10.1.1.3", 
    targetdir = "/data/dir3/",
    delete = true,
    rsync = {
        archive = true,
        compress = true,
        verbose = true,
        rsh = "/usr/bin/ssh -p 22 -o StrictHostKeyChecking=no"
    }
}
EOF
    systemctl enable lsyncd
}

# debian code
krun::install::lsyncd::debian() {
    krun::install::lsyncd::common
    apt update -y
    apt install lsyncd
    tee /etc/lsyncd/lsyncd.conf.lua <<EOF
settings {
    logfile = "/var/log/lsyncd/lsyncd.log",
    statusFile = "/var/log/lsyncd/lsyncd.status",
    nodaemon = false
}

-- rsync /data/dir1
sync {
    default.rsyncssh,
    source = "/data/dir1/",
    host = "10.1.1.1", 
    targetdir = "/data/dir1/",
    delete = true,
    rsync = {
        archive = true,
        compress = true,
        verbose = true,
        rsh = "/usr/bin/ssh -p 22 -o StrictHostKeyChecking=no"
    }
}

-- rsync /data/dir2
sync {
    default.rsyncssh,
    source = "/data/dir2/",
    host = "10.1.1.2", 
    targetdir = "/data/dir2/",
    delete = true,
    rsync = {
        archive = true,
        compress = true,
        verbose = true,
        rsh = "/usr/bin/ssh -p 22 -o StrictHostKeyChecking=no"
    }
}

-- rsync /data/dir3
sync {
    default.rsyncssh,
    source = "/data/dir3/",
    host = "10.1.1.3", 
    targetdir = "/data/dir3/",
    delete = true,
    rsync = {
        archive = true,
        compress = true,
        verbose = true,
        rsh = "/usr/bin/ssh -p 22 -o StrictHostKeyChecking=no"
    }
}
EOF
    systemctl enable lsyncd
}

# mac code
krun::install::lsyncd::mac() {
    krun::install::lsyncd::common
}

# common code
krun::install::lsyncd::common() {
    echo "${FUNCNAME}"
}

# run main
krun::install::lsyncd::run "$@"
