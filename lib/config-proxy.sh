#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# 使代理在当前终端生效：source 本脚本 或 eval "$(krun config-proxy.sh)"
# To apply in current shell: source lib/config-proxy.sh  OR  eval "$(krun config-proxy.sh)"

# vars
PROXY_HOST="${PROXY_HOST:-10.170.1.19}"
PROXY_PORT="${PROXY_PORT:-8888}"
PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"

krun::config::proxy::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

krun::config::proxy::centos() { krun::config::proxy::common; }
krun::config::proxy::debian() { krun::config::proxy::common; }
krun::config::proxy::mac()   { krun::config::proxy::common; }

krun::config::proxy::common() {
    if [[ "${BASH_SOURCE[0]:-}" != "${0}" ]]; then
        # 被 source 时：直接导出到当前 shell
        export http_proxy="$PROXY_URL"
        export https_proxy="$PROXY_URL"
        export HTTP_PROXY="$PROXY_URL"
        export HTTPS_PROXY="$PROXY_URL"
        export no_proxy="${no_proxy:-127.0.0.1,localhost}"
        export NO_PROXY="${NO_PROXY:-$no_proxy}"
        echo "✓ 代理已生效（当前终端）: http/https = $PROXY_URL"
        return
    fi
    # 直接执行时：输出 export 命令，便于 eval "$(krun config-proxy.sh)"
    echo "export http_proxy=\"$PROXY_URL\""
    echo "export https_proxy=\"$PROXY_URL\""
    echo "export HTTP_PROXY=\"$PROXY_URL\""
    echo "export HTTPS_PROXY=\"$PROXY_URL\""
    echo "export no_proxy=\"${no_proxy:-127.0.0.1,localhost}\""
    echo "export NO_PROXY=\"\${no_proxy}\""
    echo "echo '✓ 代理已生效（当前终端）: http/https = $PROXY_URL'"
}

krun::config::proxy::run "$@"
