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
# Disk usage analysis and safe cleanup (idempotent, safe items only by default)
#
# MODE=analyze          report only
# MODE=clean            analyze then clean
# MODE=auto             analyze; clean if usage >= DISK_WARN_PERCENT (default)
# DISK_TARGET_PATH=     focus path (default: stressed mounts or /)
# DISK_WARN_PERCENT=80  warn threshold (%)
# DISK_CRIT_PERCENT=90  critical threshold (%)
# CLEAN_DRY_RUN=1       preview only, no deletes
# CLEAN_JOURNAL_DAYS=7
# CLEAN_LOG_DAYS=30
# CLEAN_TMP_DAYS=7
# TOP_N=15
# MIN_FILE_SIZE_MB=100
# DOCKER_PRUNE=0        set 1 to run docker system prune -f
# CLEAN_KERNELS=0       set 1 to remove old kernels
# OUT=                  report path (default /tmp/krun-disk-*.log)

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
stressed_mounts=()

# run code
krun::disk::analyze_cleanup::run() {
    krun::disk::analyze_cleanup::main "$@"
}

krun::disk::analyze_cleanup::has() {
    command -v "$1" >/dev/null 2>&1
}

krun::disk::analyze_cleanup::section() {
    echo ""
    echo "### $1"
    echo "----------------------------------------"
}

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
    awk -v b="$bytes" 'BEGIN {
        if (b >= 1099511627776) printf "%.1fTiB", b/1099511627776
        else if (b >= 1073741824) printf "%.1fGiB", b/1073741824
        else if (b >= 1048576) printf "%.1fMiB", b/1048576
        else if (b >= 1024) printf "%.1fKiB", b/1024
        else print b"B"
    }'
}

krun::disk::analyze_cleanup::add_freed() {
    local delta=$(($1 - $2))
    [[ "$delta" -gt 0 ]] && FREED_BYTES=$((FREED_BYTES + delta))
}

krun::disk::analyze_cleanup::collect_stressed_mounts() {
    stressed_mounts=()
    local line mount pct
    while IFS= read -r line; do
        mount=$(awk '{print $NF}' <<<"$line")
        pct=$(awk '{gsub(/%/,"",$5); print $5}' <<<"$line")
        [[ "$mount" =~ ^/ ]] && [[ "$pct" =~ ^[0-9]+$ ]] && [[ "$pct" -ge "$DISK_WARN_PERCENT" ]] &&
            stressed_mounts+=("$mount:$pct")
    done < <(df -P -h 2>/dev/null | awk 'NR>1')
}

krun::disk::analyze_cleanup::run_shell() {
    echo ""
    echo "## $1"
    echo "\$ $2"
    set +o errexit
    bash -c "$2" 2>&1 || true
    set -o errexit
}

krun::disk::analyze_cleanup::run_cmd() {
    local label="$1"
    shift
    echo ""
    echo "## $label"
    if [[ "$CLEAN_DRY_RUN" == "1" ]]; then
        echo "[DRY-RUN] $*"
        return 0
    fi
    set +o errexit
    "$@" 2>&1
    local status=$?
    set -o errexit
    [[ "$status" -eq 0 ]] && echo "✓ $label" || echo "⚠ $label failed (exit $status)"
    return "$status"
}

krun::disk::analyze_cleanup::section_overview() {
    krun::disk::analyze_cleanup::section "disk overview"
    krun::disk::analyze_cleanup::run_shell "df -h" "df -h"
    krun::disk::analyze_cleanup::run_shell "inodes" "df -hi 2>/dev/null || true"
    krun::disk::analyze_cleanup::has lsblk &&
        krun::disk::analyze_cleanup::run_shell "lsblk" "lsblk 2>/dev/null || true"
}

krun::disk::analyze_cleanup::section_stressed_mounts() {
    krun::disk::analyze_cleanup::section "stressed mounts (>= ${DISK_WARN_PERCENT}%)"
    krun::disk::analyze_cleanup::collect_stressed_mounts

    if [[ "${#stressed_mounts[@]}" -eq 0 ]]; then
        echo "✓ no mount above ${DISK_WARN_PERCENT}%"
        return 0
    fi

    local item mount pct level
    for item in "${stressed_mounts[@]}"; do
        mount="${item%%:*}"
        pct="${item##*:}"
        level="WARN"
        [[ "$pct" -ge "$DISK_CRIT_PERCENT" ]] && level="CRIT"
        echo "[$level] $mount ${pct}%"
    done
}

krun::disk::analyze_cleanup::section_dir_top() {
    local target="$1"
    krun::disk::analyze_cleanup::section "top ${TOP_N} dirs: ${target}"
    [[ -d "$target" ]] || {
        echo "✗ not found: $target"
        return 0
    }
    krun::disk::analyze_cleanup::run_shell "du" \
        "du -xh --max-depth=1 '${target}' 2>/dev/null | sort -hr | head -n $((TOP_N + 1)) || du -sh '${target}'/* 2>/dev/null | sort -hr | head -n ${TOP_N} || true"
}

krun::disk::analyze_cleanup::section_large_files() {
    local target="$1"
    krun::disk::analyze_cleanup::section "large files (>= ${MIN_FILE_SIZE_MB}MB): ${target}"
    [[ -d "$target" ]] || {
        echo "✗ not found: $target"
        return 0
    }
    krun::disk::analyze_cleanup::run_shell "find" \
        "find '${target}' -xdev -type f -size +${MIN_FILE_SIZE_MB}M -printf '%s %p\n' 2>/dev/null | sort -nr | head -n ${TOP_N} | awk '{printf \"%.1fM %s\\n\", \$1/1048576, \$2}' || find '${target}' -type f -size +${MIN_FILE_SIZE_MB}M -exec ls -lh {} + 2>/dev/null | sort -k5 -hr | head -n ${TOP_N} || true"
}

krun::disk::analyze_cleanup::section_known_hogs() {
    krun::disk::analyze_cleanup::section "common space consumers"
    local path bytes
    for path in /var/log /var/cache /tmp /var/tmp /var/crash; do
        [[ -e "$path" ]] || continue
        bytes=$(krun::disk::analyze_cleanup::dir_bytes "$path")
        echo "$path: $(krun::disk::analyze_cleanup::human_bytes "$bytes")"
    done
    if krun::disk::analyze_cleanup::has journalctl; then
        echo ""
        echo "## journal"
        journalctl --disk-usage 2>/dev/null || true
    fi
    if krun::disk::analyze_cleanup::has docker && [[ -d /var/lib/docker ]]; then
        bytes=$(krun::disk::analyze_cleanup::dir_bytes /var/lib/docker)
        echo "docker (/var/lib/docker): $(krun::disk::analyze_cleanup::human_bytes "$bytes")"
        docker system df 2>/dev/null || true
    fi
}

krun::disk::analyze_cleanup::analyze_targets() {
    local -a targets=()
    if [[ -n "$DISK_TARGET_PATH" ]]; then
        targets+=("$DISK_TARGET_PATH")
    else
        krun::disk::analyze_cleanup::collect_stressed_mounts
        if [[ "${#stressed_mounts[@]}" -gt 0 ]]; then
            local item
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

krun::disk::analyze_cleanup::cleanup_journal() {
    krun::disk::analyze_cleanup::has journalctl || return 0
    local before after
    before=$(krun::disk::analyze_cleanup::dir_bytes /var/log/journal)
    krun::disk::analyze_cleanup::run_cmd "journal (keep ${CLEAN_JOURNAL_DAYS}d)" \
        journalctl --vacuum-time="${CLEAN_JOURNAL_DAYS}d"
    after=$(krun::disk::analyze_cleanup::dir_bytes /var/log/journal)
    krun::disk::analyze_cleanup::add_freed "$before" "$after"
}

krun::disk::analyze_cleanup::cleanup_rotated_logs() {
    local path=/var/log count=0
    [[ -d "$path" ]] || return 0
    echo ""
    echo "## rotated logs (>${CLEAN_LOG_DAYS}d) in $path"
    if [[ "$CLEAN_DRY_RUN" == "1" ]]; then
        find "$path" -type f \( -name '*.gz' -o -name '*.xz' -o -name '*.1' -o -name '*.old' \) \
            -mtime +"${CLEAN_LOG_DAYS}" -print 2>/dev/null | head -n 50
        echo "[DRY-RUN] find ... -delete"
        return 0
    fi
    count=$(find "$path" -type f \( -name '*.gz' -o -name '*.xz' -o -name '*.1' -o -name '*.old' \) \
        -mtime +"${CLEAN_LOG_DAYS}" -print -delete 2>/dev/null | wc -l | tr -d ' ')
    echo "✓ removed $count stale log files"
}

krun::disk::analyze_cleanup::cleanup_package_cache() {
    local before after
    before=$(krun::disk::analyze_cleanup::dir_bytes /var/cache)
    if krun::disk::analyze_cleanup::has dnf; then
        krun::disk::analyze_cleanup::run_cmd "dnf cache" dnf clean all
    elif krun::disk::analyze_cleanup::has yum; then
        krun::disk::analyze_cleanup::run_cmd "yum cache" yum clean all
    fi
    if krun::disk::analyze_cleanup::has apt-get; then
        krun::disk::analyze_cleanup::run_cmd "apt cache" apt-get clean
        krun::disk::analyze_cleanup::run_cmd "apt autoclean" apt-get autoclean -y
    fi
    after=$(krun::disk::analyze_cleanup::dir_bytes /var/cache)
    krun::disk::analyze_cleanup::add_freed "$before" "$after"
}

krun::disk::analyze_cleanup::cleanup_stale_tmp() {
    local dir="$1"
    [[ -d "$dir" ]] || return 0
    echo ""
    echo "## stale files in $dir (>${CLEAN_TMP_DAYS}d)"
    if [[ "$CLEAN_DRY_RUN" == "1" ]]; then
        find "$dir" -mindepth 1 -maxdepth 1 -type f -atime +"${CLEAN_TMP_DAYS}" -print 2>/dev/null | head -n 30
        echo "[DRY-RUN] find $dir ... -delete"
        return 0
    fi
    local before after count
    before=$(krun::disk::analyze_cleanup::dir_bytes "$dir")
    count=$(find "$dir" -mindepth 1 -maxdepth 1 -type f -atime +"${CLEAN_TMP_DAYS}" -print -delete 2>/dev/null | wc -l | tr -d ' ')
    after=$(krun::disk::analyze_cleanup::dir_bytes "$dir")
    krun::disk::analyze_cleanup::add_freed "$before" "$after"
    echo "✓ removed $count stale files from $dir"
}

krun::disk::analyze_cleanup::cleanup_pip_cache() {
    local pip_cmd=
    krun::disk::analyze_cleanup::has pip3 && pip_cmd=pip3
    krun::disk::analyze_cleanup::has pip && pip_cmd=pip
    [[ -n "$pip_cmd" ]] || return 0
    krun::disk::analyze_cleanup::run_cmd "pip cache" "$pip_cmd" cache purge
}

krun::disk::analyze_cleanup::cleanup_docker() {
    [[ "$DOCKER_PRUNE" == "1" ]] || return 0
    krun::disk::analyze_cleanup::has docker || return 0
    krun::disk::analyze_cleanup::run_cmd "docker prune" docker system prune -f
}

krun::disk::analyze_cleanup::cleanup_old_kernels() {
    [[ "$CLEAN_KERNELS" == "1" ]] || return 0
    if krun::disk::analyze_cleanup::has package-cleanup; then
        krun::disk::analyze_cleanup::run_cmd "old kernels" package-cleanup --oldkernels --count=1 -y
    elif krun::disk::analyze_cleanup::has apt-get; then
        krun::disk::analyze_cleanup::run_cmd "old kernels" apt-get autoremove -y
    fi
}

krun::disk::analyze_cleanup::run_analyze() {
    krun::disk::analyze_cleanup::section_overview
    krun::disk::analyze_cleanup::section_stressed_mounts
    krun::disk::analyze_cleanup::section_known_hogs
    krun::disk::analyze_cleanup::analyze_targets
}

krun::disk::analyze_cleanup::run_clean() {
    krun::disk::analyze_cleanup::section "safe cleanup"
    [[ "$CLEAN_DRY_RUN" == "1" ]] && echo ">>> DRY-RUN: no files will be deleted"
    echo "items: journal, rotated logs, package cache, tmp, pip"
    echo "optional: DOCKER_PRUNE=1 CLEAN_KERNELS=1"

    krun::disk::analyze_cleanup::cleanup_journal
    krun::disk::analyze_cleanup::cleanup_rotated_logs
    krun::disk::analyze_cleanup::cleanup_package_cache
    krun::disk::analyze_cleanup::cleanup_stale_tmp /tmp
    krun::disk::analyze_cleanup::cleanup_stale_tmp /var/tmp
    krun::disk::analyze_cleanup::cleanup_pip_cache
    krun::disk::analyze_cleanup::cleanup_docker
    krun::disk::analyze_cleanup::cleanup_old_kernels

    krun::disk::analyze_cleanup::section "disk after cleanup"
    df -h
    echo ""
    echo "estimated freed: $(krun::disk::analyze_cleanup::human_bytes "$FREED_BYTES")"
}

krun::disk::analyze_cleanup::main() {
    if [[ -z "$OUT" ]]; then
        OUT="/tmp/krun-disk-$(date '+%Y%m%d-%H%M%S' 2>/dev/null || date +%s).log"
    fi

    {
        echo "Krun disk analyze / cleanup"
        echo "time: $(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date)"
        echo "host: $(hostname 2>/dev/null || echo unknown)"
        echo "mode: $MODE"
        echo "warn: ${DISK_WARN_PERCENT}%  target: ${DISK_TARGET_PATH:-<auto>}  dry-run: $CLEAN_DRY_RUN"
        echo "report: $OUT"
        echo "----------------------------------------"

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
            krun::disk::analyze_cleanup::collect_stressed_mounts
            if [[ "${#stressed_mounts[@]}" -gt 0 ]]; then
                echo ""
                echo ">>> stressed mounts detected, running safe cleanup..."
                krun::disk::analyze_cleanup::run_clean
            else
                echo ""
                echo "✓ disk usage OK (< ${DISK_WARN_PERCENT}%), skip cleanup"
                echo "  force cleanup: MODE=clean $0"
            fi
            ;;
        *)
            echo "✗ invalid MODE=$MODE (analyze | clean | auto)"
            exit 1
            ;;
        esac

        echo "----------------------------------------"
        echo "done. report: $OUT"
    } | tee "$OUT"
}

# run main
krun::disk::analyze_cleanup::run "$@"
