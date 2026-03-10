#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-proxy.sh | bash
# 使代理在当前终端生效：source 本脚本 或 eval "$(krun config-proxy.sh)"

# vars
PROXY_HOST="${PROXY_HOST:-10.170.1.19}"
PROXY_PORT="${PROXY_PORT:-8888}"
PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"

# run code
krun::config::proxy::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::proxy::centos() {
    krun::config::proxy::common
}

# debian code
krun::config::proxy::debian() {
    krun::config::proxy::common
}

# mac code
krun::config::proxy::mac() {
    krun::config::proxy::common
}

# common code
krun::config::proxy::common() {
    if [[ "${BASH_SOURCE[0]:-}" != "${0}" ]]; then
        export http_proxy="$PROXY_URL"
        export https_proxy="$PROXY_URL"
        export HTTP_PROXY="$PROXY_URL"
        export HTTPS_PROXY="$PROXY_URL"
        export no_proxy="${no_proxy:-127.0.0.1,localhost}"
        export NO_PROXY="${NO_PROXY:-$no_proxy}"
        echo "✓ 代理已生效（当前终端）: http/https = $PROXY_URL"
        return
    fi
    echo "export http_proxy=\"$PROXY_URL\""
    echo "export https_proxy=\"$PROXY_URL\""
    echo "export HTTP_PROXY=\"$PROXY_URL\""
    echo "export HTTPS_PROXY=\"$PROXY_URL\""
    echo "export no_proxy=\"${no_proxy:-127.0.0.1,localhost}\""
    echo "export NO_PROXY=\"\${no_proxy}\""
    echo "echo '✓ 代理已生效（当前终端）: http/https = $PROXY_URL'"
}

# run main
krun::config::proxy::run "$@"
