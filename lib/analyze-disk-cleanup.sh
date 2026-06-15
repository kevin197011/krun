#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/analyze-disk-cleanup.sh | sudo bash
#
# 一键智能磁盘分析 + 安全清理（可重复执行，默认仅做安全项）
#
# MODE=analyze   仅分析，不清理
# MODE=clean     执行安全清理（先输出简要分析）
# MODE=auto      先分析，分区使用率 >= DISK_WARN_PERCENT 时自动安全清理（默认）
#
# DISK_TARGET_PATH=/data     重点分析指定目录（默认：使用率过高的挂载点）
# DISK_WARN_PERCENT=80       告警阈值（%）
# DISK_CRIT_PERCENT=90       严重阈值（%）
# CLEAN_DRY_RUN=1            预演：只显示将清理的内容，不实际删除
# CLEAN_JOURNAL_DAYS=7       journal 保留天数
# CLEAN_LOG_DAYS=30          压缩/轮转日志保留天数
# CLEAN_TMP_DAYS=7           /tmp 文件保留天数
# TOP_N=15                   目录占用 Top N
# MIN_FILE_SIZE_MB=100       大文件报告阈值（MB）
# DOCKER_PRUNE=0             1=执行 docker system prune -f
# CLEAN_KERNELS=0            1=清理旧内核（yum/dnf/apt）
# OUT=                        报告输出路径（默认 /tmp/krun-disk-*.log）

# vars
MODE=${MODE:-auto}
DISK_TARGET_PATH=${DISK_TARGET_PATH:-}
DISK_WARN_PERCENT=${DISK_WARN_PERCENT:-80}
DISK_CRIT_PERCENT=${DISK_CRIT_PERCENT:-90}
CLEAN_DRY_RUN=${CLEAN_DRY_RUN:-0}
CLEAN_JOURNAL_DAYS=${CLEAN_JOURNAL_DAYS:-7}
CLEAN_LOG_DAYS=${CLEAN_LOG_DAYS:-30}
CLEAN_TMP_DAYS=${CLEAN_TMP_DAYS:-7}
TOP_N=${TOP_N:-15}
MIN_FILE_SIZE_MB=${MIN_FILE_SIZE_MB:-100}
DOCKER_PRUNE=${DOCKER_PRUNE:-0}
CLEAN_KERNELS=${CLEAN_KERNELS:-0}
OUT=${OUT:-}

FREED_BYTES=0

# run code
krun::disk::analyze_cleanup::run() {
    local platform='debian'
    [[ "$(uname -s 2>/dev/null || true)" == "Darwin" ]] && platform='mac'
    command -v yum >/dev/null 2>&1 && platform='centos'
    command -v dnf >/dev/null 2>&1 && platform='centos'
    eval "${FUNCNAME/::run/::${platform}}"
}

krun::disk::analyze_cleanup::centos() { krun::disk::analyze_cleanup::common; }
krun::disk::analyze_cleanup::debian() { krun::disk::analyze_cleanup::common; }
krun::disk::analyze_cleanup::mac() { krun::disk::analyze_cleanup::common; }

krun::disk::analyze_cleanup::now() {
    date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date
}

krun::disk::analyze_cleanup::hr() {
    echo "----------------------------------------"
}

krun::disk::analyze_cleanup::title() {
    echo ""
    echo "### $1"
    krun::disk::analyze_cleanup::hr
}

krun::disk::analyze_cleanup::has() {
    command -v "$1" >/dev/null 2>&1
}

# 目录字节数（失败返回 0）
krun::disk::analyze_cleanup::dir_bytes() {
    local path="$1"
    [[ -e "$path" ]] || {
        echo 0
        return 0
    }
    if du -sb "$path" >/dev/null 2>&1; then
        du -sb "$path" 2>/dev/null | awk '{print $1}'
    else
        du -sk "$path" 2>/dev/null | awk '{print $1 * 1024}'
    fi
}

krun::disk::analyze_cleanup::human_bytes() {
    local bytes="$1"
    if krun::disk::analyze_cleanup::has numfmt; then
        numfmt --to=iec-i --suffix=B "$bytes" 2>/dev/null && return 0
    fi
    awk -v b="$bytes" '
        function fmt(x,u) { return sprintf("%.1f%s", x, u) }
        BEGIN {
            if (b >= 1099511627776) print fmt(b/1099511627776,"TiB")
            else if (b >= 1073741824) print fmt(b/1073741824,"GiB")
            else if (b >= 1048576) print fmt(b/1048576,"MiB")
            else if (b >= 1024) print fmt(b/1024,"KiB")
            else print b"B"
        }'
}

krun::disk::analyze_cleanup::mount_use_percent() {
    local target="$1"
    df -P "$target" 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}' || echo 0
}

krun::disk::analyze_cleanup::add_freed() {
    local before="$1" after="$2"
    local delta=$((before - after))
    [[ "$delta" -gt 0 ]] && FREED_BYTES=$((FREED_BYTES + delta))
}

krun::disk::analyze_cleanup::run_cmd() {
    local label="$1"
    local cmd="$2"
    echo ""
    echo "## $label"
    echo "\$ $cmd"
    set +o errexit
    bash -c "$cmd" 2>&1 || true
    set -o errexit
}

krun::disk::analyze_cleanup::section_overview() {
    krun::disk::analyze_cleanup::title "磁盘总览"
    krun::disk::analyze_cleanup::run_cmd "df -h" "df -h"
    krun::disk::analyze_cleanup::run_cmd "inode" "df -hi 2>/dev/null || true"
    if krun::disk::analyze_cleanup::has lsblk; then
        krun::disk::analyze_cleanup::run_cmd "lsblk" "lsblk 2>/dev/null || true"
    fi
}

krun::disk::analyze_cleanup::collect_stressed_mounts() {
    local line mount pct use
    stressed_mounts=()
    while IFS= read -r line; do
        mount=$(echo "$line" | awk '{print $NF}')
        pct=$(echo "$line" | awk '{gsub(/%/,"",$5); print $5}')
        [[ "$mount" =~ ^/ ]] || continue
        [[ "$pct" =~ ^[0-9]+$ ]] || continue
        if [[ "$pct" -ge "$DISK_WARN_PERCENT" ]]; then
            stressed_mounts+=("$mount:$pct")
        fi
    done < <(df -P -h 2>/dev/null | awk 'NR>1')
}

krun::disk::analyze_cleanup::section_stressed_mounts() {
    krun::disk::analyze_cleanup::title "高占用分区 (>= ${DISK_WARN_PERCENT}%)"
    krun::disk::analyze_cleanup::collect_stressed_mounts

    if [[ "${#stressed_mounts[@]}" -eq 0 ]]; then
        echo "✓ 未发现使用率 >= ${DISK_WARN_PERCENT}% 的分区"
        return 0
    fi

    local item mount pct level
    for item in "${stressed_mounts[@]}"; do
        mount="${item%%:*}"
        pct="${item##*:}"
        level="WARN"
        [[ "$pct" -ge "$DISK_CRIT_PERCENT" ]] && level="CRIT"
        echo "[$level] ${mount} 使用率 ${pct}%"
    done
}

krun::disk::analyze_cleanup::section_dir_top() {
    local target="$1"
    krun::disk::analyze_cleanup::title "目录占用 Top ${TOP_N}: ${target}"

    if [[ ! -d "$target" ]]; then
        echo "✗ 目录不存在: ${target}"
        return 0
    fi

    krun::disk::analyze_cleanup::run_cmd "du top" \
        "du -xh --max-depth=1 '${target}' 2>/dev/null | sort -hr | head -n $((TOP_N + 1)) || du -sh '${target}'/* 2>/dev/null | sort -hr | head -n ${TOP_N} || true"
}

krun::disk::analyze_cleanup::section_known_hogs() {
    krun::disk::analyze_cleanup::title "常见占用源"

    local path bytes label
    local -a checks=(
        "/var/log:系统日志"
        "/var/cache:软件包/应用缓存"
        "/tmp:临时文件"
        "/var/tmp:临时文件"
        "/var/crash:崩溃转储"
    )

    for label in "${checks[@]}"; do
        path="${label%%:*}"
        label="${label##*:}"
        [[ -e "$path" ]] || continue
        bytes=$(krun::disk::analyze_cleanup::dir_bytes "$path")
        echo "${label} (${path}): $(krun::disk::analyze_cleanup::human_bytes "$bytes")"
    done

    if krun::disk::analyze_cleanup::has journalctl; then
        echo ""
        echo "## systemd journal"
        journalctl --disk-usage 2>/dev/null || true
    fi

    if krun::disk::analyze_cleanup::has docker && [[ -d /var/lib/docker ]]; then
        bytes=$(krun::disk::analyze_cleanup::dir_bytes /var/lib/docker)
        echo "Docker (/var/lib/docker): $(krun::disk::analyze_cleanup::human_bytes "$bytes")"
        docker system df 2>/dev/null || true
    fi
}

krun::disk::analyze_cleanup::section_large_files() {
    local target="$1"
    krun::disk::analyze_cleanup::title "大文件 (>= ${MIN_FILE_SIZE_MB}MB): ${target}"

    if [[ ! -d "$target" ]]; then
        echo "✗ 目录不存在: ${target}"
        return 0
    fi

    krun::disk::analyze_cleanup::run_cmd "find large files" \
        "find '${target}' -xdev -type f -size +${MIN_FILE_SIZE_MB}M -printf '%s %p\n' 2>/dev/null | sort -nr | head -n ${TOP_N} | awk '{printf \"%.1fM %s\\n\", \$1/1048576, \$2}' || find '${target}' -type f -size +${MIN_FILE_SIZE_MB}M -exec ls -lh {} + 2>/dev/null | sort -k5 -hr | head -n ${TOP_N} || true"
}

krun::disk::analyze_cleanup::analyze_targets() {
    local -a targets=()

    if [[ -n "$DISK_TARGET_PATH" ]]; then
        targets+=("$DISK_TARGET_PATH")
    else
        krun::disk::analyze_cleanup::collect_stressed_mounts
        local item mount
        if [[ "${#stressed_mounts[@]}" -gt 0 ]]; then
            for item in "${stressed_mounts[@]}"; do
                targets+=("${item%%:*}")
            done
        else
            targets+=("/")
        fi
    fi

    local t
    for t in "${targets[@]}"; do
        krun::disk::analyze_cleanup::section_dir_top "$t"
        krun::disk::analyze_cleanup::section_large_files "$t"
    done
}

krun::disk::analyze_cleanup::needs_cleanup() {
    krun::disk::analyze_cleanup::collect_stressed_mounts
    [[ "${#stressed_mounts[@]}" -gt 0 ]]
}

krun::disk::analyze_cleanup::cleanup_action() {
    local label="$1"
    local before after
    shift
    local -a cmd=("$@")

    echo ""
    echo "## ${label}"
    if [[ "$CLEAN_DRY_RUN" == "1" ]]; then
        echo "[DRY-RUN] ${cmd[*]}"
        return 0
    fi

    before=0
    after=0
    case "$label" in
        *journal*)
            before=$(krun::disk::analyze_cleanup::dir_bytes /var/log/journal 2>/dev/null || echo 0)
            ;;
        *yum*|*dnf*|*apt*)
            before=$(krun::disk::analyze_cleanup::dir_bytes /var/cache 2>/dev/null || echo 0)
            ;;
        *tmp*)
            before=$(krun::disk::analyze_cleanup::dir_bytes /tmp 2>/dev/null || echo 0)
            ;;
    esac

    set +o errexit
    "${cmd[@]}" 2>&1
    local status=$?
    set -o errexit
    [[ "$status" -eq 0 ]] && echo "✓ ${label}" || echo "⚠ ${label} 部分失败 (exit ${status})"

    case "$label" in
        *journal*)
            after=$(krun::disk::analyze_cleanup::dir_bytes /var/log/journal 2>/dev/null || echo 0)
            krun::disk::analyze_cleanup::add_freed "$before" "$after"
            ;;
        *yum*|*dnf*|*apt*)
            after=$(krun::disk::analyze_cleanup::dir_bytes /var/cache 2>/dev/null || echo 0)
            krun::disk::analyze_cleanup::add_freed "$before" "$after"
            ;;
        *tmp*)
            after=$(krun::disk::analyze_cleanup::dir_bytes /tmp 2>/dev/null || echo 0)
            krun::disk::analyze_cleanup::add_freed "$before" "$after"
            ;;
    esac
}

krun::disk::analyze_cleanup::cleanup_journal() {
    krun::disk::analyze_cleanup::has journalctl || return 0
    krun::disk::analyze_cleanup::cleanup_action \
        "journal 清理 (保留 ${CLEAN_JOURNAL_DAYS} 天)" \
        journalctl --vacuum-time="${CLEAN_JOURNAL_DAYS}d"
}

krun::disk::analyze_cleanup::cleanup_rotated_logs() {
    local path count=0
    for path in /var/log; do
        [[ -d "$path" ]] || continue
        echo ""
        echo "## 轮转/过期日志 (${path}, >${CLEAN_LOG_DAYS} 天)"
        if [[ "$CLEAN_DRY_RUN" == "1" ]]; then
            find "$path" -type f \( -name '*.gz' -o -name '*.xz' -o -name '*.1' -o -name '*.old' \) \
                -mtime +"${CLEAN_LOG_DAYS}" -print 2>/dev/null | head -n 50
            echo "[DRY-RUN] find ... -delete"
            continue
        fi
        count=$(find "$path" -type f \( -name '*.gz' -o -name '*.xz' -o -name '*.1' -o -name '*.old' \) \
            -mtime +"${CLEAN_LOG_DAYS}" -print -delete 2>/dev/null | wc -l | tr -d ' ')
        echo "✓ 已删除 ${count} 个过期日志文件"
    done
}

krun::disk::analyze_cleanup::cleanup_package_cache() {
    if krun::disk::analyze_cleanup::has dnf; then
        krun::disk::analyze_cleanup::cleanup_action "dnf 缓存" dnf clean all
    elif krun::disk::analyze_cleanup::has yum; then
        krun::disk::analyze_cleanup::cleanup_action "yum 缓存" yum clean all
    fi
    if krun::disk::analyze_cleanup::has apt-get; then
        krun::disk::analyze_cleanup::cleanup_action "apt 缓存" apt-get clean
        krun::disk::analyze_cleanup::cleanup_action "apt 自动清理" apt-get autoclean -y
    fi
}

krun::disk::analyze_cleanup::cleanup_tmp() {
    [[ -d /tmp ]] || return 0
    echo ""
    echo "## /tmp 过期文件 (>${CLEAN_TMP_DAYS} 天未访问)"
    if [[ "$CLEAN_DRY_RUN" == "1" ]]; then
        find /tmp -mindepth 1 -maxdepth 1 -type f -atime +"${CLEAN_TMP_DAYS}" -print 2>/dev/null | head -n 30
        echo "[DRY-RUN] find /tmp ... -type f -atime +${CLEAN_TMP_DAYS} -delete"
        return 0
    fi
    local count
    count=$(find /tmp -mindepth 1 -maxdepth 1 -type f -atime +"${CLEAN_TMP_DAYS}" -print -delete 2>/dev/null | wc -l | tr -d ' ')
    echo "✓ 已删除 ${count} 个 /tmp 过期文件"
}

krun::disk::analyze_cleanup::cleanup_var_tmp() {
    [[ -d /var/tmp ]] || return 0
    echo ""
    echo "## /var/tmp 过期文件 (>${CLEAN_TMP_DAYS} 天未访问)"
    if [[ "$CLEAN_DRY_RUN" == "1" ]]; then
        find /var/tmp -mindepth 1 -maxdepth 1 -type f -atime +"${CLEAN_TMP_DAYS}" -print 2>/dev/null | head -n 30
        echo "[DRY-RUN] find /var/tmp ... -delete"
        return 0
    fi
    local count
    count=$(find /var/tmp -mindepth 1 -maxdepth 1 -type f -atime +"${CLEAN_TMP_DAYS}" -print -delete 2>/dev/null | wc -l | tr -d ' ')
    echo "✓ 已删除 ${count} 个 /var/tmp 过期文件"
}

krun::disk::analyze_cleanup::cleanup_pip_cache() {
    krun::disk::analyze_cleanup::has pip3 || krun::disk::analyze_cleanup::has pip || return 0
    local pip_cmd=pip3
    krun::disk::analyze_cleanup::has pip3 || pip_cmd=pip
    krun::disk::analyze_cleanup::cleanup_action "pip 缓存" "$pip_cmd" cache purge
}

krun::disk::analyze_cleanup::cleanup_docker() {
    [[ "$DOCKER_PRUNE" == "1" ]] || return 0
    krun::disk::analyze_cleanup::has docker || return 0
    krun::disk::analyze_cleanup::cleanup_action "Docker 未使用资源" docker system prune -f
}

krun::disk::analyze_cleanup::cleanup_old_kernels() {
    [[ "$CLEAN_KERNELS" == "1" ]] || return 0
    if krun::disk::analyze_cleanup::has package-cleanup; then
        krun::disk::analyze_cleanup::cleanup_action "旧内核 (package-cleanup)" \
            package-cleanup --oldkernels --count=1 -y
    elif krun::disk::analyze_cleanup::has apt-get; then
        krun::disk::analyze_cleanup::cleanup_action "旧内核 (autoremove)" apt-get autoremove -y
    fi
}

krun::disk::analyze_cleanup::run_analyze() {
    krun::disk::analyze_cleanup::section_overview
    krun::disk::analyze_cleanup::section_stressed_mounts
    krun::disk::analyze_cleanup::section_known_hogs
    krun::disk::analyze_cleanup::analyze_targets
}

krun::disk::analyze_cleanup::run_clean() {
    krun::disk::analyze_cleanup::title "安全清理"
    [[ "$CLEAN_DRY_RUN" == "1" ]] && echo ">>> DRY-RUN 模式：仅预演，不实际删除"
    echo "清理项: journal / 轮转日志 / 包管理器缓存 / tmp / pip"
    echo "可选: DOCKER_PRUNE=1 CLEAN_KERNELS=1"

    krun::disk::analyze_cleanup::cleanup_journal
    krun::disk::analyze_cleanup::cleanup_rotated_logs
    krun::disk::analyze_cleanup::cleanup_package_cache
    krun::disk::analyze_cleanup::cleanup_tmp
    krun::disk::analyze_cleanup::cleanup_var_tmp
    krun::disk::analyze_cleanup::cleanup_pip_cache
    krun::disk::analyze_cleanup::cleanup_docker
    krun::disk::analyze_cleanup::cleanup_old_kernels

    krun::disk::analyze_cleanup::title "清理后磁盘"
    df -h
    echo ""
    echo "估算释放: $(krun::disk::analyze_cleanup::human_bytes "$FREED_BYTES")"
}

krun::disk::analyze_cleanup::write_header() {
    echo "Krun Disk Analyze / Cleanup"
    echo "Time: $(krun::disk::analyze_cleanup::now)"
    echo "Host: $(hostname 2>/dev/null || echo unknown)"
    echo "Mode: ${MODE}"
    echo "DISK_WARN_PERCENT: ${DISK_WARN_PERCENT}%"
    echo "DISK_TARGET_PATH: ${DISK_TARGET_PATH:-<auto>}"
    echo "CLEAN_DRY_RUN: ${CLEAN_DRY_RUN}"
    echo "Report: ${OUT}"
    krun::disk::analyze_cleanup::hr
}

krun::disk::analyze_cleanup::common() {
    if [[ -z "$OUT" ]]; then
        local ts
        ts="$(date '+%Y%m%d-%H%M%S' 2>/dev/null || date)"
        OUT="/tmp/krun-disk-${ts}.log"
    fi

    stressed_mounts=()

    {
        krun::disk::analyze_cleanup::write_header

        case "$MODE" in
            analyze)
                krun::disk::analyze_cleanup::run_analyze
                ;;
            clean)
                krun::disk::analyze_cleanup::run_analyze
                krun::disk::analyze_cleanup::run_clean
                ;;
            auto)
                krun::disk::analyze_cleanup::run_analyze
                if krun::disk::analyze_cleanup::needs_cleanup; then
                    echo ""
                    echo ">>> 检测到高占用分区，开始安全清理..."
                    krun::disk::analyze_cleanup::run_clean
                else
                    echo ""
                    echo "✓ 磁盘使用率正常 (< ${DISK_WARN_PERCENT}%)，跳过自动清理"
                    echo "  强制清理: MODE=clean bash $0"
                fi
                ;;
            *)
                echo "✗ 无效 MODE=${MODE}，可选: analyze | clean | auto"
                exit 1
                ;;
        esac

        krun::disk::analyze_cleanup::hr
        echo "Done. Report: ${OUT}"
    } | tee "$OUT"
}

# run main
krun::disk::analyze_cleanup::run "$@"
