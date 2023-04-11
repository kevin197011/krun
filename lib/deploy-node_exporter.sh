# Copyright (c) 2023 kk
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

mkdir -pv /opt/docker-compose/node_exporter/ && \
tee /opt/docker-compose/node_exporter/docker-compose.yml <<EOF
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

cd /opt/docker-compose/node_exporter/ && docker compose up -d && \
curl http://localhost:9100/metrics