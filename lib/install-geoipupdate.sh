#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-geoipupdate.sh | bash

# vars

# run code
krun::install::geoipupdate::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::geoipupdate::centos() {
    source_version=$(curl -s https://api.github.com/repos/maxmind/geoipupdate/releases/latest | jq -r .tag_name)
    version="${source_version#v}"
    yum install -y https://github.com/maxmind/geoipupdate/releases/download/${source_version}/geoipupdate_${version}_linux_amd64.rpm
    krun::install::geoipupdate::common
}

# debian code
krun::install::geoipupdate::debian() {
    add-apt-repository ppa:maxmind/ppa
    apt update
    apt install geoipupdate
    krun::install::geoipupdate::common
}

# mac code
krun::install::geoipupdate::mac() {
    krun::install::geoipupdate::common
}

# common code
krun::install::geoipupdate::common() {
    mkdir -p /data/geoip
    tee /usr/local/etc/GeoIP.conf <<EOF
AccountID <id>
LicenseKey <key>
EditionIDs GeoLite2-ASN GeoLite2-City GeoLite2-Country
DatabaseDirectory /data/geoip
EOF
    geoipupdate
}

# run main
krun::install::geoipupdate::run "$@"
