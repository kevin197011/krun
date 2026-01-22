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
    # 华北地区
    "北京:114.114.114.114:114DNS"
    "北京:223.5.5.5:阿里DNS"
    "北京:119.29.29.29:腾讯DNS"
    "北京:180.76.76.76:百度DNS"
    "天津:114.114.115.115:114DNS"
    "天津:223.6.6.6:阿里DNS"
    "石家庄:119.28.28.28:腾讯DNS"
    "石家庄:8.8.8.8:GoogleDNS"
    "太原:114.114.114.114:114DNS"
    "太原:1.1.1.1:Cloudflare"
    "呼和浩特:223.5.5.5:阿里DNS"
    "呼和浩特:119.29.29.29:腾讯DNS"
    # 东北地区
    "沈阳:114.114.115.115:114DNS"
    "沈阳:180.76.76.76:百度DNS"
    "大连:114.114.114.114:114DNS"
    "大连:223.6.6.6:阿里DNS"
    "长春:119.28.28.28:腾讯DNS"
    "长春:8.8.4.4:GoogleDNS"
    "哈尔滨:114.114.114.114:114DNS"
    "哈尔滨:223.5.5.5:阿里DNS"
    # 华东地区
    "上海:180.76.76.76:百度DNS"
    "上海:119.29.29.29:腾讯DNS"
    "上海:114.114.114.114:114DNS"
    "上海:223.5.5.5:阿里DNS"
    "南京:114.114.115.115:114DNS"
    "南京:119.28.28.28:腾讯DNS"
    "杭州:223.6.6.6:阿里DNS"
    "杭州:114.114.114.114:114DNS"
    "合肥:180.76.76.76:百度DNS"
    "合肥:223.5.5.5:阿里DNS"
    "福州:119.29.29.29:腾讯DNS"
    "福州:114.114.115.115:114DNS"
    "厦门:119.28.28.28:腾讯DNS"
    "厦门:223.6.6.6:阿里DNS"
    "南昌:114.114.114.114:114DNS"
    "南昌:180.76.76.76:百度DNS"
    "济南:223.5.5.5:阿里DNS"
    "济南:119.29.29.29:腾讯DNS"
    "青岛:114.114.115.115:114DNS"
    "青岛:119.28.28.28:腾讯DNS"
    "苏州:223.6.6.6:阿里DNS"
    "苏州:114.114.114.114:114DNS"
    "无锡:180.76.76.76:百度DNS"
    "无锡:223.5.5.5:阿里DNS"
    "宁波:119.29.29.29:腾讯DNS"
    "宁波:114.114.115.115:114DNS"
    "温州:119.28.28.28:腾讯DNS"
    "温州:223.6.6.6:阿里DNS"
    # 华中地区
    "郑州:180.76.76.76:百度DNS"
    "郑州:114.114.114.114:114DNS"
    "武汉:223.5.5.5:阿里DNS"
    "武汉:119.29.29.29:腾讯DNS"
    "长沙:114.114.115.115:114DNS"
    "长沙:119.28.28.28:腾讯DNS"
    # 华南地区
    "广州:1.1.1.1:Cloudflare"
    "广州:114.114.114.114:114DNS"
    "广州:223.5.5.5:阿里DNS"
    "广州:119.29.29.29:腾讯DNS"
    "深圳:8.8.8.8:GoogleDNS"
    "深圳:114.114.115.115:114DNS"
    "深圳:223.6.6.6:阿里DNS"
    "深圳:180.76.76.76:百度DNS"
    "南宁:119.28.28.28:腾讯DNS"
    "南宁:114.114.114.114:114DNS"
    "海口:223.5.5.5:阿里DNS"
    "海口:119.29.29.29:腾讯DNS"
    "佛山:114.114.115.115:114DNS"
    "佛山:180.76.76.76:百度DNS"
    "东莞:119.28.28.28:腾讯DNS"
    "东莞:223.6.6.6:阿里DNS"
    "中山:114.114.114.114:114DNS"
    "中山:223.5.5.5:阿里DNS"
    "珠海:119.29.29.29:腾讯DNS"
    "珠海:114.114.115.115:114DNS"
    # 西南地区
    "成都:114.114.115.115:114DNS"
    "成都:223.5.5.5:阿里DNS"
    "成都:119.29.29.29:腾讯DNS"
    "成都:180.76.76.76:百度DNS"
    "重庆:119.28.28.28:腾讯DNS"
    "重庆:114.114.114.114:114DNS"
    "重庆:223.6.6.6:阿里DNS"
    "贵阳:114.114.115.115:114DNS"
    "贵阳:223.5.5.5:阿里DNS"
    "昆明:119.29.29.29:腾讯DNS"
    "昆明:180.76.76.76:百度DNS"
    "拉萨:114.114.114.114:114DNS"
    "拉萨:119.28.28.28:腾讯DNS"
    # 西北地区
    "西安:180.76.76.76:百度DNS"
    "西安:114.114.114.114:114DNS"
    "西安:223.5.5.5:阿里DNS"
    "西安:119.29.29.29:腾讯DNS"
    "兰州:114.114.115.115:114DNS"
    "兰州:119.28.28.28:腾讯DNS"
    "西宁:223.6.6.6:阿里DNS"
    "西宁:114.114.114.114:114DNS"
    "银川:180.76.76.76:百度DNS"
    "银川:223.5.5.5:阿里DNS"
    "乌鲁木齐:119.29.29.29:腾讯DNS"
    "乌鲁木齐:114.114.115.115:114DNS"
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
        return 0
    fi

    local ping_cmd
    local result

    # Linux ping format
    if [[ "$(uname)" == "Linux" ]]; then
        ping_cmd="ping -c $count -W $timeout $ip 2>/dev/null || true"
    else
        # macOS ping format (timeout in milliseconds)
        ping_cmd="ping -c $count -W $((timeout * 1000)) $ip 2>/dev/null || true"
    fi

    result=$(eval "$ping_cmd" | grep -E "min/avg/max|round-trip" | tail -1 || true)
    if [[ -n "$result" ]]; then
        # Extract average latency
        echo "$result" | awk -F'/' '{print $5}' 2>/dev/null || echo "timeout"
    else
        echo "timeout"
    fi
}

# connectivity test
krun::check::ip_quality::connectivity_test() {
    local ip="$1"
    local port="${2:-53}"

    if command -v nc >/dev/null 2>&1; then
        (timeout 2 nc -z "$ip" "$port" >/dev/null 2>&1 && echo "✓") || echo "✗"
    elif command -v telnet >/dev/null 2>&1; then
        (timeout 2 bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null && echo "✓") || echo "✗"
    else
        # Fallback: ping only
        (ping -c 1 -W 2 "$ip" >/dev/null 2>&1 && echo "✓") || echo "✗"
    fi
}

# test single node (output to temp file for concurrent execution)
krun::check::ip_quality::test_node() {
    local region="$1"
    local ip="$2"
    local desc="$3"
    local output_file="$4"

    {
        printf "%-8s %-18s %-12s " "$region" "$ip" "$desc" || true

        # Connectivity test
        local conn
        conn=$(krun::check::ip_quality::connectivity_test "$ip" || echo "✗")
        printf "%-4s " "$conn" || true

        # Ping test (average latency)
        local latency
        latency=$(krun::check::ip_quality::ping_test "$ip" 4 3 || echo "timeout")
        if [[ "$latency" == "timeout" ]] || [[ -z "$latency" ]]; then
            printf "%-12s\n" "timeout" || true
        else
            printf "%-12s\n" "${latency}ms" || true
        fi
    } >"$output_file" 2>/dev/null
}

# common code
krun::check::ip_quality::common() {
    echo "全国各地公共 IP 网络质量检测 (并发执行)"
    echo "=========================================="
    echo ""

    # Check if ping is available
    if ! command -v ping >/dev/null 2>&1; then
        echo "错误: 未找到 ping 命令，请先安装 iputils-ping 或 inetutils-ping"
        exit 1
    fi

    # Create temp directory for results
    local temp_dir
    temp_dir=$(mktemp -d /tmp/krun_ip_quality_XXXXXX) || {
        echo "错误: 无法创建临时目录"
        exit 1
    }
    trap "rm -rf $temp_dir" EXIT INT TERM

    # Print header
    printf "%-8s %-18s %-12s %-4s %-12s\n" "地区" "IP地址" "描述" "连通" "平均延迟"
    echo "----------------------------------------"

    # Concurrent execution settings
    local max_jobs="${MAX_JOBS:-20}"
    local pids=()

    # Test each node concurrently
    set +o errexit
    local total=0
    local index=0
    for node in "${TEST_NODES[@]}"; do
        IFS=':' read -r region ip desc <<<"$node" || continue
        ((total++)) || true
        ((index++)) || true

        # Wait if we've reached max concurrent jobs
        while [[ ${#pids[@]} -ge $max_jobs ]]; do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                    unset "pids[$i]"
                fi
            done
            # Rebuild array to remove empty elements
            pids=("${pids[@]}")
            sleep 0.1
        done

        # Start background job
        local output_file="$temp_dir/node_${index}.txt"
        krun::check::ip_quality::test_node "$region" "$ip" "$desc" "$output_file" &
        pids+=($!)
    done

    # Wait for all background jobs to complete
    wait
    set -o errexit

    # Collect and display results (sorted by index)
    local success=0
    local i=1
    while [[ $i -le $total ]]; do
        local result_file="$temp_dir/node_${i}.txt"
        if [[ -f "$result_file" ]]; then
            cat "$result_file"
            # Check if connectivity is successful
            if grep -q "✓" "$result_file" 2>/dev/null; then
                ((success++)) || true
            fi
        fi
        ((i++)) || true
    done

    echo "----------------------------------------"
    echo ""
    echo "检测完成: 总计 $total 个节点, 成功 $success 个, 失败 $((total - success)) 个"
    echo "成功率: $((success * 100 / total))%"

    # Cleanup
    rm -rf "$temp_dir"
    trap - EXIT INT TERM
}

# run main
krun::check::ip_quality::run "$@"
