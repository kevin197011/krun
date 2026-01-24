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

# test single node (output to temp file for concurrent execution)
krun::check::ip_quality::test_node() {
    local region="$1"
    local ip="$2"
    local desc="$3"
    local output_file="$4"
    local data_file="$5"

    {
        printf "%-8s %-18s %-12s " "$region" "$ip" "$desc" || true

        # Ping test (average latency)
        local latency
        latency=$(krun::check::ip_quality::ping_test "$ip" 4 3 || echo "timeout")
        if [[ "$latency" == "timeout" ]] || [[ -z "$latency" ]]; then
            printf "%-4s " "✗" || true
            printf "%-12s\n" "timeout" || true
            echo "$region|$ip|$desc|✗|timeout" >>"$data_file" || true
        else
            printf "%-4s " "✓" || true
            printf "%-12s\n" "${latency}ms" || true
            echo "$region|$ip|$desc|✓|$latency" >>"$data_file" || true
        fi
    } >"$output_file" 2>/dev/null
}

# progress display (concurrent)
krun::check::ip_quality::progress() {
    # Disable errexit inside progress loop
    set +o errexit

    local temp_dir="$1"
    local total="$2"
    local spinner='-\|/'
    local idx=0

    while true; do
        local done
        done=$(ls "$temp_dir"/node_*.txt 2>/dev/null | wc -l | tr -d ' ' 2>/dev/null)
        [[ -z "${done:-}" ]] && done=0

        idx=$(((idx + 1) % 4))
        printf "\r检测中... %s %s/%s" "${spinner:$idx:1}" "$done" "$total"

        if [[ "$done" -ge "$total" ]]; then
            break
        fi
        sleep 0.2
    done

    printf "\r检测完成...   %s/%s\n" "$total" "$total"
    set -o errexit
}

# evaluate results
krun::check::ip_quality::evaluate() {
    local data_file="$1"
    local total="$2"
    local success="$3"

    if [[ ! -f "$data_file" ]] || [[ ! -s "$data_file" ]]; then
        return 0
    fi

    echo "=========================================="
    echo "网络质量评估报告"
    echo "=========================================="
    echo ""

    # Analyze latency
    local excellent=0 # <50ms
    local good=0      # 50-100ms
    local fair=0      # 100-200ms
    local poor=0      # >200ms
    local timeout_count=0
    local total_latency=0
    local latency_count=0

    while IFS='|' read -r region ip desc conn latency; do
        # Analyze latency
        if [[ "$latency" == "timeout" ]]; then
            ((timeout_count++)) || true
        else
            # Extract numeric value
            local latency_num
            latency_num=$(echo "$latency" | grep -oE '[0-9]+\.?[0-9]*' | head -1)
            if [[ -n "$latency_num" ]]; then
                total_latency=$(awk "BEGIN {printf \"%.2f\", $total_latency + $latency_num}" 2>/dev/null || echo "$total_latency")
                ((latency_count++)) || true

                if awk "BEGIN {exit !($latency_num < 50)}" 2>/dev/null; then
                    ((excellent++)) || true
                elif awk "BEGIN {exit !($latency_num < 100)}" 2>/dev/null; then
                    ((good++)) || true
                elif awk "BEGIN {exit !($latency_num < 200)}" 2>/dev/null; then
                    ((fair++)) || true
                else
                    ((poor++)) || true
                fi
            fi
        fi
    done <"$data_file"

    # Calculate average latency
    local avg_latency="N/A"
    if [[ $latency_count -gt 0 ]]; then
        avg_latency=$(awk "BEGIN {printf \"%.2f\", $total_latency / $latency_count}" 2>/dev/null || echo "N/A")
    fi

    # 1. Connectivity Assessment
    echo "【连通性评估】"
    local success_rate=$((success * 100 / total))
    if [[ $success_rate -ge 95 ]]; then
        echo "  等级: 优秀 (${success_rate}%)"
        echo "  评价: 网络连通性极佳，几乎无丢包"
    elif [[ $success_rate -ge 85 ]]; then
        echo "  等级: 良好 (${success_rate}%)"
        echo "  评价: 网络连通性良好，偶有丢包"
    elif [[ $success_rate -ge 70 ]]; then
        echo "  等级: 一般 (${success_rate}%)"
        echo "  评价: 网络连通性一般，存在一定丢包"
    else
        echo "  等级: 较差 (${success_rate}%)"
        echo "  评价: 网络连通性较差，丢包较多"
    fi
    echo ""

    # 2. Latency Assessment
    echo "【延迟评估】"
    if [[ "$avg_latency" != "N/A" ]]; then
        echo "  平均延迟: ${avg_latency}ms"
        if awk "BEGIN {exit !($avg_latency < 50)}" 2>/dev/null; then
            echo "  等级: 优秀"
            echo "  评价: 延迟极低，网络响应迅速"
        elif awk "BEGIN {exit !($avg_latency < 100)}" 2>/dev/null; then
            echo "  等级: 良好"
            echo "  评价: 延迟较低，网络响应良好"
        elif awk "BEGIN {exit !($avg_latency < 200)}" 2>/dev/null; then
            echo "  等级: 一般"
            echo "  评价: 延迟中等，网络响应一般"
        else
            echo "  等级: 较差"
            echo "  评价: 延迟较高，网络响应较慢"
        fi
    else
        echo "  平均延迟: 无法计算"
    fi
    echo ""

    # 3. Latency Distribution
    echo "【延迟分布】"
    local total_valid=$((excellent + good + fair + poor))
    if [[ $total_valid -gt 0 ]]; then
        echo "  优秀 (<50ms):   $excellent 个 ($((excellent * 100 / total_valid))%)"
        echo "  良好 (50-100ms): $good 个 ($((good * 100 / total_valid))%)"
        echo "  一般 (100-200ms): $fair 个 ($((fair * 100 / total_valid))%)"
        echo "  较差 (>200ms):   $poor 个 ($((poor * 100 / total_valid))%)"
        if [[ $timeout_count -gt 0 ]]; then
            echo "  超时:           $timeout_count 个"
        fi
    fi
    echo ""

    # 4. Regional Coverage
    echo "【地区覆盖评估】"
    local region_count=0
    local excellent_regions=0
    local good_regions=0
    local fair_regions=0
    local poor_regions=0

    # Compute regional buckets via awk (works on macOS bash 3.2)
    read -r region_count excellent_regions good_regions fair_regions poor_regions < <(
        awk -F'|' '
          { tot[$1]++; if ($4=="✓") ok[$1]++ }
          END {
            rc=0; ex=0; gd=0; fr=0; pr=0;
            for (r in tot) {
              rc++;
              rate = (ok[r] ? ok[r] : 0) * 100 / tot[r];
              if (rate >= 90) ex++;
              else if (rate >= 70) gd++;
              else if (rate >= 50) fr++;
              else pr++;
            }
            print rc, ex, gd, fr, pr
          }' "$data_file" 2>/dev/null
    )

    echo "  检测地区数: ${region_count:-0} 个"
    echo "  优秀地区 (≥90%): ${excellent_regions:-0} 个"
    echo "  良好地区 (70-90%): ${good_regions:-0} 个"
    echo "  一般地区 (50-70%): ${fair_regions:-0} 个"
    echo "  较差地区 (<50%): ${poor_regions:-0} 个"
    echo ""

    # 5. Overall Score
    echo "【综合评分】"
    local score=0
    # Connectivity score (40 points)
    score=$((score + success_rate * 40 / 100))
    # Latency score (40 points)
    if [[ "$avg_latency" != "N/A" ]]; then
        if awk "BEGIN {exit !($avg_latency < 50)}" 2>/dev/null; then
            score=$((score + 40))
        elif awk "BEGIN {exit !($avg_latency < 100)}" 2>/dev/null; then
            score=$((score + 35))
        elif awk "BEGIN {exit !($avg_latency < 200)}" 2>/dev/null; then
            score=$((score + 25))
        else
            score=$((score + 15))
        fi
    fi
    # Regional coverage score (20 points)
    if [[ ${region_count:-0} -gt 0 ]]; then
        local coverage_score=$((excellent_regions * 20 / region_count))
        score=$((score + coverage_score))
    fi

    echo "  总分: ${score}/100"
    if [[ $score -ge 90 ]]; then
        echo "  等级: 优秀"
        echo "  评价: 网络质量优秀，适合各种应用场景"
    elif [[ $score -ge 75 ]]; then
        echo "  等级: 良好"
        echo "  评价: 网络质量良好，适合大多数应用场景"
    elif [[ $score -ge 60 ]]; then
        echo "  等级: 一般"
        echo "  评价: 网络质量一般，建议优化网络配置"
    else
        echo "  等级: 较差"
        echo "  评价: 网络质量较差，建议检查网络连接和配置"
    fi
    echo ""

    # 6. Recommendations
    echo "【优化建议】"
    if [[ $success_rate -lt 85 ]]; then
        echo "  • 检查网络连接稳定性，可能存在丢包问题"
    fi
    if [[ "$avg_latency" != "N/A" ]] && awk "BEGIN {exit !($avg_latency > 100)}" 2>/dev/null; then
        echo "  • 延迟较高，建议检查网络路由和DNS配置"
    fi
    if [[ $timeout_count -gt $((total / 10)) ]]; then
        echo "  • 超时节点较多，建议检查防火墙和网络策略"
    fi
    if [[ $poor_regions -gt $((region_count / 4)) ]]; then
        echo "  • 部分地区连通性较差，建议检查跨地区网络质量"
    fi
    if [[ $score -ge 75 ]]; then
        echo "  • 网络质量良好，保持当前配置即可"
    fi
    echo ""
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

    # Data file for analysis
    local data_file="$temp_dir/data.txt"
    touch "$data_file"

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
        krun::check::ip_quality::test_node "$region" "$ip" "$desc" "$output_file" "$data_file" &
        pids+=($!)
    done

    # Progress display while waiting
    krun::check::ip_quality::progress "$temp_dir" "$total" &
    local progress_pid=$!

    # Wait for all background jobs to complete
    wait
    kill "$progress_pid" >/dev/null 2>&1 || true
    wait "$progress_pid" >/dev/null 2>&1 || true
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
    echo ""

    # Generate evaluation report
    krun::check::ip_quality::evaluate "$data_file" "$total" "$success"

    # Cleanup
    rm -rf "$temp_dir"
    trap - EXIT INT TERM
}

# run main
krun::check::ip_quality::run "$@"
