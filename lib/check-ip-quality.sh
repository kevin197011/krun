#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/check-ip-quality.sh | bash

# vars
# 全国各地公共 IP 测试节点 (地区:IP:描述)
declare -a TEST_NODES=(
    "北京:114.114.114.114:114DNS"
    "北京:223.5.5.5:阿里DNS"
    "上海:180.76.76.76:百度DNS"
    "上海:119.29.29.29:腾讯DNS"
    "广州:1.1.1.1:Cloudflare"
    "深圳:8.8.8.8:GoogleDNS"
    "杭州:223.6.6.6:阿里DNS"
    "成都:114.114.115.115:114DNS"
    "重庆:119.28.28.28:腾讯DNS"
    "西安:180.76.76.76:百度DNS"
    "武汉:223.5.5.5:阿里DNS"
    "南京:114.114.114.114:114DNS"
    "天津:119.29.29.29:腾讯DNS"
    "苏州:223.6.6.6:阿里DNS"
    "郑州:180.76.76.76:百度DNS"
    "长沙:114.114.115.115:114DNS"
    "东莞:119.28.28.28:腾讯DNS"
    "青岛:223.5.5.5:阿里DNS"
    "大连:114.114.114.114:114DNS"
    "厦门:119.29.29.29:腾讯DNS"
)

# run code
krun::check::ip_quality::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::check::ip_quality::centos() {
    krun::check::ip_quality::common
}

# debian code
krun::check::ip_quality::debian() {
    krun::check::ip_quality::common
}

# mac code
krun::check::ip_quality::mac() {
    krun::check::ip_quality::common
}

# ping test
krun::check::ip_quality::ping_test() {
    local ip="$1"
    local count="${2:-4}"
    local timeout="${3:-3}"

    if ! command -v ping >/dev/null 2>&1; then
        echo "N/A"
        return
    fi

    local ping_cmd
    local result

    # Linux ping format
    if [[ "$(uname)" == "Linux" ]]; then
        ping_cmd="ping -c $count -W $timeout $ip 2>/dev/null"
    else
        # macOS ping format (timeout in milliseconds)
        ping_cmd="ping -c $count -W $((timeout * 1000)) $ip 2>/dev/null"
    fi

    result=$(eval "$ping_cmd" | grep -E "min/avg/max|round-trip" | tail -1)
    if [[ -n "$result" ]]; then
        # Extract average latency
        echo "$result" | awk -F'/' '{print $5}' || echo "timeout"
    else
        echo "timeout"
    fi
}

# connectivity test
krun::check::ip_quality::connectivity_test() {
    local ip="$1"
    local port="${2:-53}"

    if command -v nc >/dev/null 2>&1; then
        timeout 2 nc -z "$ip" "$port" >/dev/null 2>&1 && echo "✓" || echo "✗"
    elif command -v telnet >/dev/null 2>&1; then
        timeout 2 bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null && echo "✓" || echo "✗"
    else
        # Fallback: ping only
        ping -c 1 -W 2 "$ip" >/dev/null 2>&1 && echo "✓" || echo "✗"
    fi
}

# test single node
krun::check::ip_quality::test_node() {
    local region="$1"
    local ip="$2"
    local desc="$3"

    printf "%-8s %-18s %-12s " "$region" "$ip" "$desc"

    # Connectivity test
    local conn=$(krun::check::ip_quality::connectivity_test "$ip")
    printf "%-4s " "$conn"

    # Ping test (average latency)
    local latency=$(krun::check::ip_quality::ping_test "$ip" 4 3)
    if [[ "$latency" == "timeout" ]] || [[ -z "$latency" ]]; then
        printf "%-12s\n" "timeout"
    else
        printf "%-12s\n" "${latency}ms"
    fi
}

# common code
krun::check::ip_quality::common() {
    echo "全国各地公共 IP 网络质量检测"
    echo "=========================================="
    echo ""

    # Check if ping is available
    if ! command -v ping >/dev/null 2>&1; then
        echo "错误: 未找到 ping 命令，请先安装 iputils-ping 或 inetutils-ping"
        exit 1
    fi

    # Print header
    printf "%-8s %-18s %-12s %-4s %-12s\n" "地区" "IP地址" "描述" "连通" "平均延迟"
    echo "----------------------------------------"

    # Test each node
    local total=0
    local success=0
    for node in "${TEST_NODES[@]}"; do
        IFS=':' read -r region ip desc <<<"$node"
        krun::check::ip_quality::test_node "$region" "$ip" "$desc"
        ((total++))
        if [[ $(krun::check::ip_quality::connectivity_test "$ip") == "✓" ]]; then
            ((success++))
        fi
    done

    echo "----------------------------------------"
    echo ""
    echo "检测完成: 总计 $total 个节点, 成功 $success 个, 失败 $((total - success)) 个"
    echo "成功率: $((success * 100 / total))%"
}

# run main
krun::check::ip_quality::run "$@"
