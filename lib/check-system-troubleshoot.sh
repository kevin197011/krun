#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/check-system-troubleshoot.sh | bash

# vars
OUT="${OUT:-}"
MODE="${MODE:-full}"         # full | quick
TOP_N="${TOP_N:-15}"         # top processes count
LINES="${LINES:-200}"        # tail lines for logs
MAX_JOBS="${MAX_JOBS:-4}"    # parallel sections

krun::check::system_troubleshoot::platform() {
  if [[ "$(uname -s 2>/dev/null || true)" == "Darwin" ]]; then
    echo "mac"
    return
  fi

  if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
    echo "centos"
    return
  fi

  echo "debian"
}

krun::check::system_troubleshoot::now() {
  date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date
}

krun::check::system_troubleshoot::hr() {
  echo "----------------------------------------"
}

krun::check::system_troubleshoot::title() {
  echo ""
  echo "### $1"
  krun::check::system_troubleshoot::hr
}

krun::check::system_troubleshoot::has() {
  command -v "$1" >/dev/null 2>&1
}

krun::check::system_troubleshoot::run() {
  local label="$1"
  local cmd="$2"

  echo ""
  echo "## $label"
  echo "\$ $cmd"

  set +o errexit
  bash -c "$cmd" 2>&1 || true
  set -o errexit
}

krun::check::system_troubleshoot::write_header() {
  echo "Krun System Troubleshoot Report"
  echo "Time: $(krun::check::system_troubleshoot::now)"
  echo "Host: $(hostname 2>/dev/null || echo unknown)"
  echo "User: $(id -un 2>/dev/null || echo unknown)"
  echo "Platform: $(krun::check::system_troubleshoot::platform)"
  echo "Mode: $MODE"
  echo "MAX_JOBS: $MAX_JOBS"
  echo "TOP_N: $TOP_N"
  echo "LINES: $LINES"
  echo "Report: $OUT"
  krun::check::system_troubleshoot::hr
}

krun::check::system_troubleshoot::section_basic() {
  krun::check::system_troubleshoot::title "基本信息"
  krun::check::system_troubleshoot::run "uname" "uname -a"
  krun::check::system_troubleshoot::run "os-release" "test -f /etc/os-release && cat /etc/os-release || true"
  krun::check::system_troubleshoot::run "uptime" "uptime"
  krun::check::system_troubleshoot::run "date" "date"
  krun::check::system_troubleshoot::run "who" "who || true"
}

krun::check::system_troubleshoot::section_cpu_mem() {
  krun::check::system_troubleshoot::title "CPU / 内存"
  krun::check::system_troubleshoot::run "loadavg" "cat /proc/loadavg 2>/dev/null || uptime"
  krun::check::system_troubleshoot::run "cpuinfo" "nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || true"
  krun::check::system_troubleshoot::run "meminfo" "free -h 2>/dev/null || vm_stat 2>/dev/null || true"
  krun::check::system_troubleshoot::run "top (snapshot)" "top -b -n 1 2>/dev/null | head -n 40 || top -l 1 -n 0 2>/dev/null | head -n 40 || true"
  krun::check::system_troubleshoot::run "top processes (cpu)" "ps aux 2>/dev/null | head -1; ps aux 2>/dev/null | sort -nrk 3,3 | head -n $((TOP_N+1)) || true"
  krun::check::system_troubleshoot::run "top processes (mem)" "ps aux 2>/dev/null | head -1; ps aux 2>/dev/null | sort -nrk 4,4 | head -n $((TOP_N+1)) || true"
}

krun::check::system_troubleshoot::section_disk() {
  krun::check::system_troubleshoot::title "磁盘 / 文件系统"
  krun::check::system_troubleshoot::run "df" "df -h"
  krun::check::system_troubleshoot::run "mount" "mount | head -n 200 || true"
  krun::check::system_troubleshoot::run "lsblk" "lsblk 2>/dev/null || diskutil list 2>/dev/null || true"
  krun::check::system_troubleshoot::run "inode" "df -hi 2>/dev/null || true"
  krun::check::system_troubleshoot::run "dmesg disk errors (tail)" "dmesg 2>/dev/null | tail -n $LINES || true"
}

krun::check::system_troubleshoot::section_network() {
  krun::check::system_troubleshoot::title "网络"
  krun::check::system_troubleshoot::run "ip addr / ifconfig" "ip addr 2>/dev/null || ifconfig 2>/dev/null || true"
  krun::check::system_troubleshoot::run "link stats" "ip -s link 2>/dev/null | head -n 200 || netstat -ib 2>/dev/null | head -n 200 || true"
  krun::check::system_troubleshoot::run "ip route / netstat -rn" "ip route 2>/dev/null || netstat -rn 2>/dev/null || true"
  krun::check::system_troubleshoot::run "dns" "cat /etc/resolv.conf 2>/dev/null || scutil --dns 2>/dev/null | head -n 200 || true"
  krun::check::system_troubleshoot::run "ping (1.1.1.1)" "ping -c 3 -W 2 1.1.1.1 2>/dev/null || ping -c 3 1.1.1.1 2>/dev/null || true"
  krun::check::system_troubleshoot::run "curl (https://www.baidu.com)" "curl -I -m 5 -sS https://www.baidu.com 2>/dev/null | head -n 20 || true"
}

krun::check::system_troubleshoot::section_ports_connections() {
  krun::check::system_troubleshoot::title "端口 / 连接数"
  if krun::check::system_troubleshoot::has ss; then
    krun::check::system_troubleshoot::run "ss summary" "ss -s || true"
    krun::check::system_troubleshoot::run "listening ports" "ss -lntup 2>/dev/null | head -n 200 || true"
    krun::check::system_troubleshoot::run "top remote connections" "ss -ntu 2>/dev/null | awk 'NR>1{print \$5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -n $TOP_N || true"
  else
    krun::check::system_troubleshoot::run "netstat summary" "netstat -an 2>/dev/null | head -n 50 || true"
    krun::check::system_troubleshoot::run "listening ports" "netstat -lnt 2>/dev/null | head -n 200 || netstat -anv 2>/dev/null | head -n 200 || true"
  fi

  if krun::check::system_troubleshoot::has lsof; then
    krun::check::system_troubleshoot::run "lsof listening" "lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | head -n 200 || true"
  fi
}

krun::check::system_troubleshoot::section_processes() {
  krun::check::system_troubleshoot::title "进程 / 服务"
  krun::check::system_troubleshoot::run "process count" "ps aux 2>/dev/null | wc -l | tr -d ' ' || true"
  if krun::check::system_troubleshoot::has systemctl; then
    krun::check::system_troubleshoot::run "failed services" "systemctl --failed --no-pager 2>/dev/null || true"
    krun::check::system_troubleshoot::run "top services by time" "systemctl list-units --type=service --state=running --no-pager 2>/dev/null | head -n 80 || true"
    krun::check::system_troubleshoot::run "journal errors (tail)" "journalctl -p err -n $LINES --no-pager 2>/dev/null || true"
  fi
}

krun::check::system_troubleshoot::section_limits() {
  krun::check::system_troubleshoot::title "资源限制 / 句柄"
  krun::check::system_troubleshoot::run "ulimit" "ulimit -a 2>/dev/null || true"
  krun::check::system_troubleshoot::run "open files (system)" "cat /proc/sys/fs/file-nr 2>/dev/null || true"
  krun::check::system_troubleshoot::run "conntrack" "cat /proc/sys/net/netfilter/nf_conntrack_count 2>/dev/null || true"
  krun::check::system_troubleshoot::run "conntrack max" "cat /proc/sys/net/netfilter/nf_conntrack_max 2>/dev/null || true"
}

krun::check::system_troubleshoot::section_io() {
  krun::check::system_troubleshoot::title "I/O / 压力"

  # Linux PSI (pressure stall information)
  krun::check::system_troubleshoot::run "pressure (cpu/memory/io)" "test -d /proc/pressure && (for f in /proc/pressure/*; do echo \"# $f\"; cat \"$f\"; done) || true"

  # vmstat / iostat (best-effort)
  krun::check::system_troubleshoot::run "vmstat (5 samples)" "vmstat 1 5 2>/dev/null || true"
  krun::check::system_troubleshoot::run "iostat (3 samples)" "iostat -xz 1 3 2>/dev/null || iostat -d 1 3 2>/dev/null || true"

  # macOS memory pressure (if present)
  krun::check::system_troubleshoot::run "memory_pressure (mac)" "memory_pressure 2>/dev/null || true"
}

krun::check::system_troubleshoot::section_time_sync() {
  krun::check::system_troubleshoot::title "时间 / NTP"
  krun::check::system_troubleshoot::run "date" "date"
  krun::check::system_troubleshoot::run "timedatectl" "timedatectl 2>/dev/null || true"
  krun::check::system_troubleshoot::run "chrony" "chronyc tracking 2>/dev/null || true"
  krun::check::system_troubleshoot::run "chrony sources" "chronyc sources -v 2>/dev/null | head -n 120 || true"
  krun::check::system_troubleshoot::run "ntpq" "ntpq -p 2>/dev/null || true"
  krun::check::system_troubleshoot::run "systemsetup (mac)" "systemsetup -getnetworktimeserver 2>/dev/null || true"
}

krun::check::system_troubleshoot::section_firewall() {
  krun::check::system_troubleshoot::title "防火墙"
  krun::check::system_troubleshoot::run "ufw" "ufw status verbose 2>/dev/null || true"
  krun::check::system_troubleshoot::run "firewalld" "firewall-cmd --state 2>/dev/null && firewall-cmd --list-all 2>/dev/null || true"
  krun::check::system_troubleshoot::run "iptables (rules)" "iptables -S 2>/dev/null | head -n 200 || true"
  krun::check::system_troubleshoot::run "nft (ruleset)" "nft list ruleset 2>/dev/null | head -n 200 || true"
  krun::check::system_troubleshoot::run "pf (mac)" "pfctl -s info 2>/dev/null || true"
  krun::check::system_troubleshoot::run "pf rules (mac)" "pfctl -sr 2>/dev/null | head -n 200 || true"
}

krun::check::system_troubleshoot::section_logs() {
  krun::check::system_troubleshoot::title "系统日志 / 错误"

  krun::check::system_troubleshoot::run "dmesg (errors tail)" "dmesg 2>/dev/null | tail -n $LINES || true"
  krun::check::system_troubleshoot::run "dmesg (oom killer)" "dmesg 2>/dev/null | tail -n 2000 | grep -iE 'oom|out of memory|killed process' 2>/dev/null | tail -n 80 || true"

  if krun::check::system_troubleshoot::has journalctl; then
    krun::check::system_troubleshoot::run "journalctl kernel errors" "journalctl -k -p err -n $LINES --no-pager 2>/dev/null || true"
    krun::check::system_troubleshoot::run "journalctl system errors" "journalctl -p err -n $LINES --no-pager 2>/dev/null || true"
  fi

  krun::check::system_troubleshoot::run "syslog/messages (tail)" "tail -n $LINES /var/log/syslog 2>/dev/null || tail -n $LINES /var/log/messages 2>/dev/null || true"
}

krun::check::system_troubleshoot::section_containers() {
  krun::check::system_troubleshoot::title "容器 (Docker)"
  if krun::check::system_troubleshoot::has docker; then
    krun::check::system_troubleshoot::run "docker version" "docker version 2>/dev/null || true"
    krun::check::system_troubleshoot::run "docker info" "docker info 2>/dev/null | head -n 160 || true"
    krun::check::system_troubleshoot::run "docker ps" "docker ps --no-trunc 2>/dev/null || true"
    krun::check::system_troubleshoot::run "docker stats (snapshot)" "docker stats --no-stream 2>/dev/null || true"
  else
    krun::check::system_troubleshoot::run "docker" "echo 'docker not found' || true"
  fi
}

krun::check::system_troubleshoot::sanitize_max_jobs() {
  case "${MAX_JOBS}" in
    ''|*[!0-9]*)
      MAX_JOBS=4
      ;;
    0)
      MAX_JOBS=1
      ;;
  esac
}

krun::check::system_troubleshoot::reap_pids() {
  # keep only running pids (portable: no wait -n on macOS bash 3.2)
  local -a keep=()
  local pid
  for pid in "${pids[@]:-}"; do
    if kill -0 "$pid" >/dev/null 2>&1; then
      keep+=("$pid")
    else
      wait "$pid" 2>/dev/null || true
    fi
  done
  pids=("${keep[@]}")
}

krun::check::system_troubleshoot::run_parallel_sections() {
  local tmp_dir="$1"

  krun::check::system_troubleshoot::sanitize_max_jobs

  local -a jobs=(
    "10_cpu_mem:krun::check::system_troubleshoot::section_cpu_mem"
    "20_disk:krun::check::system_troubleshoot::section_disk"
    "25_io:krun::check::system_troubleshoot::section_io"
    "30_network:krun::check::system_troubleshoot::section_network"
    "40_ports:krun::check::system_troubleshoot::section_ports_connections"
    "50_processes:krun::check::system_troubleshoot::section_processes"
    "60_limits:krun::check::system_troubleshoot::section_limits"
    "70_time:krun::check::system_troubleshoot::section_time_sync"
    "80_firewall:krun::check::system_troubleshoot::section_firewall"
    "90_logs:krun::check::system_troubleshoot::section_logs"
    "95_containers:krun::check::system_troubleshoot::section_containers"
  )

  pids=()
  local item key fn
  for item in "${jobs[@]}"; do
    key="${item%%:*}"
    fn="${item#*:}"

    while true; do
      krun::check::system_troubleshoot::reap_pids
      if [[ "${#pids[@]}" -lt "${MAX_JOBS}" ]]; then
        break
      fi
      sleep 0.1
    done

    (
      eval "$fn"
    ) >"$tmp_dir/${key}.txt" 2>&1 &
    pids+=("$!")
  done

  local pid
  for pid in "${pids[@]:-}"; do
    wait "$pid" 2>/dev/null || true
  done
}

krun::check::system_troubleshoot::print_parallel_sections() {
  local tmp_dir="$1"
  local f
  for f in "$tmp_dir"/*.txt; do
    [[ -f "$f" ]] || continue
    cat "$f"
  done
}

# run code
krun::check::system_troubleshoot::common() {
  if [[ -z "$OUT" ]]; then
    local ts
    ts="$(date '+%Y%m%d-%H%M%S' 2>/dev/null || date)"
    OUT="/tmp/krun-troubleshoot-${ts}.log"
  fi

  local tmp_dir
  tmp_dir="$(mktemp -d /tmp/krun-troubleshoot-XXXXXX 2>/dev/null || mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT INT TERM

  {
    krun::check::system_troubleshoot::write_header
    krun::check::system_troubleshoot::section_basic

    if [[ "$MODE" == "quick" ]]; then
      krun::check::system_troubleshoot::section_cpu_mem
      krun::check::system_troubleshoot::section_disk
      krun::check::system_troubleshoot::section_io
      krun::check::system_troubleshoot::section_network
      krun::check::system_troubleshoot::section_ports_connections
      krun::check::system_troubleshoot::section_processes
      krun::check::system_troubleshoot::section_limits
      krun::check::system_troubleshoot::section_time_sync
      krun::check::system_troubleshoot::section_logs
    else
      krun::check::system_troubleshoot::run_parallel_sections "$tmp_dir"
      krun::check::system_troubleshoot::print_parallel_sections "$tmp_dir"
    fi

    krun::check::system_troubleshoot::hr
    echo "Done. Report saved to: $OUT"
  } | tee "$OUT"
}

krun::check::system_troubleshoot::centos() {
  krun::check::system_troubleshoot::common
}

krun::check::system_troubleshoot::debian() {
  krun::check::system_troubleshoot::common
}

krun::check::system_troubleshoot::mac() {
  krun::check::system_troubleshoot::common
}

krun::check::system_troubleshoot::run() {
  local platform
  platform="$(krun::check::system_troubleshoot::platform)"
  eval "${FUNCNAME/::run/::${platform}}"
}

# run main
krun::check::system_troubleshoot::run "$@"

