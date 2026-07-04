#!/usr/bin/env bash
# Copyright (c) 2026 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install-node-exporter-offline.sh | sudo bash
#
# Offline install node_exporter (requires pre-downloaded tarball)
#   node_exporter-1.11.1.linux-amd64.tar.gz
#
# Usage:
#   sudo bash install-node-exporter-offline.sh
#   sudo node_exporter_tarball=/path/to/node_exporter-1.11.1.linux-amd64.tar.gz bash install-node-exporter-offline.sh
#
# idempotent: safe to re-run

# vars
node_exporter_version=${node_exporter_version:-1.11.1}
node_exporter_tarball=${node_exporter_tarball:-node_exporter-${node_exporter_version}.linux-amd64.tar.gz}
node_exporter_install_dir=${node_exporter_install_dir:-/usr/local/bin}
node_exporter_service=${node_exporter_service:-node_exporter.service}

# run code
krun::install::node_exporter_offline::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

krun::install::node_exporter_offline::require_root() {
    [[ "${EUID:-$(id -u)}" -eq 0 ]] || {
        echo "✗ must run as root"
        exit 1
    }
}

krun::install::node_exporter_offline::resolve_tarball() {
    local candidate

    if [[ "${node_exporter_tarball}" = /* ]]; then
        candidate="${node_exporter_tarball}"
    elif [[ -f "${node_exporter_tarball}" ]]; then
        candidate="${node_exporter_tarball}"
    elif [[ -f "$(dirname "$0")/${node_exporter_tarball}" ]]; then
        candidate="$(dirname "$0")/${node_exporter_tarball}"
    else
        echo "✗ offline tarball not found: ${node_exporter_tarball}"
        echo "  place node_exporter-${node_exporter_version}.linux-amd64.tar.gz in cwd or set node_exporter_tarball="
        exit 1
    fi

    printf '%s' "${candidate}"
}

krun::install::node_exporter_offline::centos() {
    krun::install::node_exporter_offline::common
}

krun::install::node_exporter_offline::debian() {
    krun::install::node_exporter_offline::common
}

krun::install::node_exporter_offline::mac() {
    echo "✗ node_exporter offline install supports Linux only"
    exit 1
}

krun::install::node_exporter_offline::install_binary() {
    local tarball="$1"
    local tmpdir binary dest

    command -v tar >/dev/null || {
        echo "✗ tar not found"
        exit 1
    }

    tmpdir="$(mktemp -d)"

    tar -xzf "${tarball}" -C "${tmpdir}"
    binary="$(find "${tmpdir}" -type f -name node_exporter | head -1)"
    [[ -n "${binary}" ]] || {
        rm -rf "${tmpdir}"
        echo "✗ node_exporter binary not found in ${tarball}"
        exit 1
    }

    dest="${node_exporter_install_dir}/node_exporter"
    install -d "${node_exporter_install_dir}"
    install -m 755 "${binary}" "${dest}"
    rm -rf "${tmpdir}"
    echo "✓ installed ${dest}"
    "${dest}" --version 2>/dev/null || true
}

krun::install::node_exporter_offline::install_service() {
    local unit="/etc/systemd/system/${node_exporter_service}"
    local content changed=0

    content="[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
ExecStart=${node_exporter_install_dir}/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
"

    if [[ -f "${unit}" ]] && cmp -s <(printf '%s' "${content}") "${unit}"; then
        echo "✓ ${unit} unchanged, skip"
    else
        printf '%s' "${content}" >"${unit}"
        changed=1
        echo "✓ wrote ${unit}"
    fi

    command -v systemctl >/dev/null || {
        echo "✗ systemctl not found"
        exit 1
    }

    [[ "${changed}" -eq 1 ]] && systemctl daemon-reload
    systemctl enable "${node_exporter_service}"
    systemctl restart "${node_exporter_service}"
    echo "✓ ${node_exporter_service} enabled and running"
}

krun::install::node_exporter_offline::verify() {
    systemctl is-active --quiet "${node_exporter_service}" && echo "✓ service active"
    curl -sf http://127.0.0.1:9100/metrics >/dev/null && echo "✓ metrics endpoint OK" || echo "⚠ metrics endpoint not ready yet"
}

krun::install::node_exporter_offline::common() {
    local tarball

    krun::install::node_exporter_offline::require_root
    tarball="$(krun::install::node_exporter_offline::resolve_tarball)"
    echo "using offline tarball: ${tarball}"

    krun::install::node_exporter_offline::install_binary "${tarball}"
    krun::install::node_exporter_offline::install_service
    krun::install::node_exporter_offline::verify
}

# run main
krun::install::node_exporter_offline::run "$@"
