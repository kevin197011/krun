#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# vars

# run code
krun::config::acme::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::acme::centos() {
    krun::config::acme::common
}

# debian code
krun::config::acme::debian() {
    krun::config::acme::common
}

# mac code
krun::config::acme::mac() {
    krun::config::acme::common
}

# common code
krun::config::acme::common() {
    # usage: sh $0 kevin197011@outlook.com devops.io

    # variables
    # sh $0 $1[email]
    req_email=${1:-'kevin197011@outlook.com'}
    # devops.io
    domain=$2

    # source /etc/acme.sh/config.sh
    # export CF_Email="kevin197011@outlook.com"
    # export CF_Key="xxxxxx"

    [[ -f /etc/acme.sh/config.sh ]] && source /etc/acme.sh/config.sh

    # acme.sh
    [[ -f /root/.acme.sh/acme.sh ]] || (curl -sf https://get.acme.sh | sh -s email=${req_email})

    /root/.acme.sh/acme.sh --upgrade --auto-upgrade

    # issue ssl
    /root/.acme.sh/acme.sh --issue --dns dns_cf -d "*.${domain}"

    # install ssl
    /root/.acme.sh/acme.sh --install-cert -d ${domain} \
        --key-file /www/server/panel/vhost/cert/${domain}/${domain}.key \
        --fullchain-file /www/server/panel/vhost/cert/${domain}/${domain}.crt \
        --ca-file /www/server/panel/vhost/cert/${domain}/${domain}.ca.crt \
        --reloadcmd "systemctl restart nginx"
}

# run main
krun::config::acme::run "$@"
