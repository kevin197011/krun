#!/usr/bin/env bash

# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::deploy::node_exporter::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::deploy::node_exporter::centos() {
    krun::deploy::node_exporter::common
}

# debian code
krun::deploy::node_exporter::debian() {
    krun::deploy::node_exporter::common
}

# common code
krun::deploy::node_exporter::common() {
    mkdir -pv /opt/docker-compose/node_exporter/ &&
        tee /opt/docker-compose/node_exporter/compose.yml <<EOF
---
version: '3.8'

services:
  node_exporter:
    image: quay.io/prometheus/node-exporter:latest
    container_name: node_exporter
    command:
      - '--path.rootfs=/host'
    network_mode: host
    pid: host
    restart: unless-stopped
    volumes:
      - '/:/host:ro,rslave'
EOF

    cd /opt/docker-compose/node_exporter/ &&
        docker compose up -d &&
        curl http://localhost:9100/metrics
}

# run main
krun::deploy::node_exporter::run "$@"
