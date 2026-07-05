#!/usr/bin/env python3
# Copyright (c) 2026 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/init-system.py | sudo python3
#
# system initialization (packages, tuning, limits)
# supported: Rocky 8/9, AlmaLinux 8/9, RHEL 8/9, CentOS Stream 8/9,
#            Debian 11/12, Ubuntu 22.04/24.04
#
# SYSTEM_TIMEZONE=Asia/Hong_Kong
# SYSTEM_LOCALE=en_US.UTF-8
# DISABLE_SELINUX=1
# DISABLE_FIREWALL=1
# SKIP_NODE_EXPORTER=1

from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

from krun.common import docker_present
from krun.handlers import config as krun_config
from krun.handlers import install as krun_install

SYSCTL_CONF = """\
# memory
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500
vm.overcommit_memory = 1
vm.overcommit_ratio = 50
vm.vfs_cache_pressure = 50
vm.min_free_kbytes = 65536

# network core
net.core.rmem_default = 262144
net.core.rmem_max = 67108864
net.core.wmem_default = 262144
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 5000
net.core.netdev_budget = 600
net.core.somaxconn = 65535
net.core.optmem_max = 81920

# tcp
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_tw_buckets = 1048576
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_sack = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_adv_win_scale = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_frto = 2
net.ipv4.tcp_no_metrics_save = 1

# ip security
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.ip_forward = 1

# docker / container host
fs.may_detach_mounts = 1
vm.max_map_count = 262144
kernel.keys.maxkeys = 2000000
kernel.keys.root_maxkeys = 2000000
fs.file-max = 2097152
fs.nr_open = 1048576
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 256

# kernel
kernel.pid_max = 4194304
kernel.threads-max = 2097152
kernel.panic = 10
kernel.hung_task_timeout_secs = 0
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1
kernel.unprivileged_bpf_disabled = 1
"""

DOCKER_SYSCTL_CONF = """\
# Docker bridge networking (requires br_netfilter)
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1

# IPv6 container networks
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1
"""

DOCKER_MODULES = "br_netfilter\n"

LIMITS_CONF = """\
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 1048576
* hard nproc 1048576
* soft memlock unlimited
* hard memlock unlimited
root soft nofile 1048576
root hard nofile 1048576
root soft nproc 1048576
root hard nproc 1048576
root soft memlock unlimited
root hard memlock unlimited
"""

THP_SERVICE = """\
[Unit]
Description=Disable Transparent Huge Pages
DefaultDependencies=false
After=sysinit.target local-fs.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/bin/sh -c 'echo never > /sys/kernel/mm/transparent_hugepage/defrag'

[Install]
WantedBy=basic.target
"""

UDEV_IOSCHED = """\
ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]n[0-9]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
"""

VIMRC_LOCAL = """\
set nocompatible
set encoding=utf-8
set paste
set number
set tabstop=4
set shiftwidth=4
set expandtab
set hlsearch
set incsearch
syntax enable
"""

TMUX_CONF = """\
set -g default-terminal "screen-256color"
set -g history-limit 10000
set -g mouse on
set -g base-index 1
set -g pane-base-index 1
"""

OPS_ALIASES = """\
alias ll='ls -alF'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias grep='grep --color=auto'
alias start='systemctl start'
alias stop='systemctl stop'
alias restart='systemctl restart'
alias status='systemctl status'
"""

RHEL_PACKAGES = [
    "bash-completion", "vim-enhanced", "git", "tree", "lrzsz", "lsof", "net-tools",
    "openssl", "openssl-devel", "wget", "curl", "rsync", "unzip", "zip",
    "python3", "python3-pip", "python3-devel",
    "ruby", "ruby-devel", "rubygems",
    "htop", "iotop", "sysstat", "tuned", "irqbalance", "numactl", "chrony",
    "bind-utils", "telnet", "traceroute", "jq", "ncdu", "screen", "tmux",
    "strace", "tcpdump", "nmap-ncat", "tar", "gzip", "bzip2", "xz",
    "psmisc", "procps-ng", "util-linux",
]

RHEL_OPTIONAL = [
    "ripgrep", "iftop", "nethogs", "mtr", "iperf3", "glances", "parallel",
    "nmon", "dstat", "atop",
]

DEB_PACKAGES = [
    "bash-completion", "vim", "git", "tree", "lrzsz", "lsof", "net-tools",
    "openssl", "libssl-dev", "wget", "curl", "rsync", "unzip", "zip",
    "python3", "python3-pip", "python3-venv", "python3-dev",
    "ruby", "ruby-dev", "ruby-bundler",
    "htop", "iotop", "sysstat", "irqbalance", "numactl", "chrony", "locales",
    "dnsutils", "telnet", "traceroute", "jq", "ncdu", "screen", "tmux",
    "strace", "tcpdump", "netcat-openbsd", "tar", "gzip", "bzip2", "xz-utils",
    "psmisc", "procps", "util-linux",
]

DISABLE_SERVICES = [
    "bluetooth", "cups", "avahi-daemon", "ModemManager", "whoopsie", "apport",
]


def has_cmd(name: str) -> bool:
    return shutil.which(name) is not None


def run(cmd: list[str] | str, *, check: bool = False, env: dict[str, str] | None = None) -> int:
    if isinstance(cmd, str):
        return subprocess.run(cmd, shell=True, check=check, env=env).returncode
    return subprocess.run(cmd, check=check, env=env).returncode


def write_text(path: Path, content: str, mode: int = 0o644) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    path.chmod(mode)


def read_os_release() -> dict[str, str]:
    data: dict[str, str] = {}
    path = Path("/etc/os-release")
    if not path.is_file():
        return data
    for line in path.read_text(encoding="utf-8").splitlines():
        if "=" not in line or line.startswith("#"):
            continue
        key, value = line.split("=", 1)
        data[key.strip()] = value.strip().strip('"')
    return data


class SystemInit:
    def __init__(self) -> None:
        self.timezone = os.environ.get("SYSTEM_TIMEZONE", "Asia/Hong_Kong")
        self.locale = os.environ.get("SYSTEM_LOCALE", "en_US.UTF-8")
        self.disable_selinux = os.environ.get("DISABLE_SELINUX", "1") == "1"
        self.disable_firewall = os.environ.get("DISABLE_FIREWALL", "1") == "1"
        self.os_release = read_os_release()
        self.distro_id = self.os_release.get("ID", "")
        self.distro_version = self.os_release.get("VERSION_ID", "")

    def platform(self) -> str:
        if sys.platform == "darwin":
            return "mac"
        if has_cmd("dnf") or has_cmd("yum"):
            return "rhel"
        if has_cmd("apt-get"):
            return "debian"
        return "unknown"

    def check_root(self) -> None:
        if sys.platform != "darwin" and os.geteuid() != 0:
            print("✗ must run as root")
            sys.exit(1)

    def check_rhel_version(self) -> None:
        major = self.distro_version.split(".", 1)[0]
        if major in {"8", "9"}:
            return
        if major == "7":
            print("⚠ RHEL family 7 is EOL, some packages may be unavailable")
        else:
            print(f"⚠ untested RHEL family version: {self.distro_version}")

    def check_debian_version(self) -> None:
        key = f"{self.distro_id}:{self.distro_version}"
        if key in {"debian:11", "debian:12", "ubuntu:22.04", "ubuntu:24.04"}:
            return
        print(f"⚠ untested Debian family version: {self.distro_id} {self.distro_version}")

    def backup_configs(self) -> None:
        root = Path("/root")
        if any(root.glob("krun-backup-*")):
            return
        backup_dir = root / f"krun-backup-{datetime.now():%Y%m%d-%H%M%S}"
        backup_dir.mkdir(parents=True, exist_ok=True)
        for config in (
            Path("/etc/sysctl.conf"),
            Path("/etc/security/limits.conf"),
            Path("/etc/systemd/system.conf"),
            Path("/etc/fstab"),
        ):
            if config.is_file():
                shutil.copy2(config, backup_dir / config.name)
        print(f"✓ configs backed up to {backup_dir}")

    def pm(self) -> str:
        return "dnf" if has_cmd("dnf") else "yum"

    def pm_install(self, pm: str, packages: list[str]) -> None:
        if not packages:
            return
        run([pm, "install", "-y", *packages])

    def install_runtimes(self) -> None:
        print("installing python3 and ruby3")
        plat = self.platform()
        if plat == "rhel":
            pm = self.pm()
            if run([pm, "module", "install", "-y", "ruby:3.1"], check=False) != 0:
                print("⚠ ruby:3.1 module unavailable, using distro ruby package")
        for cmd in ("python3", "ruby"):
            if has_cmd(cmd):
                subprocess.run([cmd, "--version"], check=False)
                print(f"✓ {cmd} ready")
            else:
                print(f"⚠ {cmd} not found after install")

    def install_packages_rhel(self) -> None:
        print("installing packages")
        pm = self.pm()
        run([pm, "update", "-y"])
        self.pm_install(pm, ["epel-release"])
        self.pm_install(pm, RHEL_PACKAGES)
        for pkg in RHEL_OPTIONAL:
            run([pm, "install", "-y", pkg])
        print("✓ packages installed")

    def install_packages_debian(self) -> None:
        print("installing packages")
        env = {**os.environ, "DEBIAN_FRONTEND": "noninteractive"}
        run(["apt-get", "update"], env=env)
        run(["apt-get", "upgrade", "-y"], env=env)
        run(["apt-get", "install", "-y", *DEB_PACKAGES], env=env)
        if self.distro_id == "ubuntu":
            run(["apt-get", "install", "-y", "mtr-tiny", "linux-tools-common",
                 "linux-tools-generic", "cpufrequtils"], env=env)
        else:
            run(["apt-get", "install", "-y", "mtr-tiny", "linux-cpupower"], env=env)
        run(["apt-get", "install", "-y", "ripgrep", "iftop", "nethogs", "iperf3",
             "glances", "parallel", "nmon", "dstat", "atop"], env=env)
        print("✓ packages installed")

    def configure_timezone(self) -> None:
        print(f"setting timezone to {self.timezone}")
        zone = Path("/usr/share/zoneinfo") / self.timezone
        if has_cmd("timedatectl"):
            run(["timedatectl", "set-timezone", self.timezone])
        elif zone.is_file():
            Path("/etc/localtime").unlink(missing_ok=True)
            Path("/etc/localtime").symlink_to(zone)
            write_text(Path("/etc/timezone"), f"{self.timezone}\n")
        else:
            print(f"✗ timezone not found: {self.timezone}")
            return
        print("✓ timezone set")

    def configure_locale(self) -> None:
        print(f"setting locale to {self.locale}")
        if has_cmd("localectl"):
            run(["localectl", "set-locale", f"LANG={self.locale}"])
        locale_conf = Path("/etc/locale.conf")
        if locale_conf.parent.exists():
            write_text(locale_conf, f"LANG={self.locale}\nLC_ALL={self.locale}\n")
        locale_gen = Path("/etc/locale.gen")
        if locale_gen.is_file():
            text = locale_gen.read_text(encoding="utf-8")
            needle = f"# {self.locale} UTF-8"
            if needle in text:
                locale_gen.write_text(text.replace(needle, f"{self.locale} UTF-8"), encoding="utf-8")
                run(["locale-gen"])
        if has_cmd("update-locale"):
            run(["update-locale", f"LANG={self.locale}"])
        print("✓ locale set")

    def configure_sysctl(self) -> None:
        print("writing sysctl tuning")
        write_text(Path("/etc/sysctl.d/99-system.conf"), SYSCTL_CONF)
        write_text(Path("/etc/sysctl.d/99-docker.conf"), DOCKER_SYSCTL_CONF)
        write_text(Path("/etc/modules-load.d/br_netfilter.conf"), DOCKER_MODULES)
        run(["modprobe", "br_netfilter"], check=False)
        print("✓ sysctl config written (system + docker)")

    def configure_limits(self) -> None:
        print("writing limits")
        write_text(Path("/etc/security/limits.d/99-system.conf"), LIMITS_CONF)
        system_conf = Path("/etc/systemd/system.conf")
        if system_conf.is_file():
            text = system_conf.read_text(encoding="utf-8")
            for key, value in (
                ("DefaultLimitNOFILE", "1048576"),
                ("DefaultLimitNPROC", "1048576"),
                ("DefaultLimitMEMLOCK", "infinity"),
            ):
                text, n = re.subn(rf"^#?{key}=.*$", f"{key}={value}", text, flags=re.M)
                if n == 0:
                    text += f"\n{key}={value}\n"
            write_text(system_conf, text)
            run(["systemctl", "daemon-reload"])
        print("✓ limits config written")

    def configure_network(self) -> None:
        for node, value in (("rmem_max", "67108864"), ("wmem_max", "67108864")):
            path = Path(f"/proc/sys/net/core/{node}")
            if path.is_file():
                path.write_text(value, encoding="utf-8")
        bbr_conf = Path("/etc/modules-load.d/bbr.conf")
        proc = subprocess.run(["lsmod"], capture_output=True, text=True, check=False)
        if "tcp_bbr" in proc.stdout or run(["modprobe", "tcp_bbr"]) == 0:
            if not bbr_conf.is_file():
                write_text(bbr_conf, "tcp_bbr\n")
            print("✓ BBR enabled")
        else:
            print("⚠ BBR module not available, skip")

    def configure_filesystem(self) -> None:
        fstab = Path("/etc/fstab")
        if fstab.is_file() and "noatime" not in fstab.read_text(encoding="utf-8"):
            shutil.copy2(fstab, fstab.with_name(f"fstab.bak.{datetime.now():%Y%m%d}"))
            text = fstab.read_text(encoding="utf-8")
            text = re.sub(r"(ext[234].*)defaults", r"\1defaults,noatime,nodiratime", text)
            text = re.sub(r"(xfs.*)defaults", r"\1defaults,noatime,nodiratime", text)
            write_text(fstab, text)
            print("✓ fstab noatime applied")
        if has_cmd("lsblk") and has_cmd("blockdev"):
            out = subprocess.check_output(["lsblk", "-nd", "-o", "NAME"], text=True)
            for name in out.split():
                if re.match(r"^(sd|nvme|vd)", name):
                    run(["blockdev", "--setra", "4096", f"/dev/{name}"])

    def configure_memory(self) -> None:
        thp = Path("/sys/kernel/mm/transparent_hugepage/enabled")
        if not thp.is_file():
            return
        Path("/sys/kernel/mm/transparent_hugepage/defrag").write_text("never\n", encoding="utf-8")
        thp.write_text("never\n", encoding="utf-8")
        service = Path("/etc/systemd/system/disable-thp.service")
        if not service.is_file():
            write_text(service, THP_SERVICE)
        run(["systemctl", "enable", "disable-thp.service"])
        numa = Path("/proc/sys/kernel/numa_balancing")
        if numa.is_file():
            numa.write_text("1\n", encoding="utf-8")
        print("✓ memory tuning applied")

    def configure_io(self) -> None:
        if has_cmd("lsblk"):
            out = subprocess.check_output(["lsblk", "-nd", "-o", "NAME,ROTA"], text=True)
            for line in out.splitlines():
                parts = line.split()
                if len(parts) != 2 or parts[1] != "0":
                    continue
                sched = Path(f"/sys/block/{parts[0]}/queue/scheduler")
                if not sched.is_file():
                    continue
                content = sched.read_text(encoding="utf-8")
                for candidate in ("mq-deadline", "none", "noop"):
                    if candidate in content:
                        sched.write_text(f"{candidate}\n", encoding="utf-8")
                        break
        write_text(Path("/etc/udev/rules.d/60-ioschedulers.rules"), UDEV_IOSCHED)
        print("✓ io scheduler configured")

    def configure_firewall(self) -> None:
        if not self.disable_firewall:
            print("✓ firewall disable skipped (DISABLE_FIREWALL=0)")
            return
        krun_config.disable_firewall()

    def configure_selinux(self) -> None:
        if not self.disable_selinux:
            return
        if docker_present():
            print("✓ docker present, keep SELinux enabled for container isolation")
            return
        config = Path("/etc/selinux/config")
        if not config.is_file():
            return
        print("disabling SELinux")
        text = re.sub(r"^SELINUX=.*$", "SELINUX=disabled", config.read_text(encoding="utf-8"), flags=re.M)
        write_text(config, text)
        run(["setenforce", "0"])
        print("✓ SELinux disabled")

    def configure_ntp(self) -> None:
        print("enabling time sync")
        units = subprocess.run(
            ["systemctl", "list-unit-files"], capture_output=True, text=True, check=False
        ).stdout
        if "chronyd.service" in units:
            run(["systemctl", "enable", "--now", "chronyd"])
            print("✓ chronyd enabled")
        elif "systemd-timesyncd.service" in units:
            run(["systemctl", "enable", "--now", "systemd-timesyncd"])
            print("✓ systemd-timesyncd enabled")
        else:
            print("⚠ no time sync service found, skip")

    def configure_tuned(self) -> None:
        if not has_cmd("tuned-adm"):
            return
        run(["systemctl", "enable", "--now", "tuned"])
        run(["tuned-adm", "profile", "throughput-performance"])
        print("✓ tuned throughput profile enabled")

    def configure_cpufreq(self) -> None:
        governors = list(Path("/sys/devices/system/cpu").glob("cpu*/cpufreq/scaling_governor"))
        if not governors:
            return
        for path in governors:
            try:
                path.write_text("performance\n", encoding="utf-8")
            except OSError:
                pass
        default = Path("/etc/default/cpufrequtils")
        if default.parent.is_dir():
            write_text(default, 'GOVERNOR="performance"\n')
        print("✓ cpufreq governor set to performance")

    def configure_tools(self) -> None:
        vimrc = Path("/etc/vimrc")
        if vimrc.is_file() and "set paste" not in vimrc.read_text(encoding="utf-8"):
            with vimrc.open("a", encoding="utf-8") as handle:
                handle.write("set paste\n")
        write_text(Path("/etc/vim/vimrc.local"), VIMRC_LOCAL)
        root_vim = Path("/root/.vimrc")
        if not root_vim.is_file():
            write_text(root_vim, "source /etc/vim/vimrc.local\n")
        for args in (
            ["git", "config", "--global", "init.defaultBranch", "main"],
            ["git", "config", "--global", "core.editor", "vim"],
            ["git", "config", "--global", "color.ui", "auto"],
        ):
            run(args)
        write_text(Path("/etc/tmux.conf"), TMUX_CONF)
        ops = Path("/etc/profile.d/ops-aliases.sh")
        write_text(ops, OPS_ALIASES, mode=0o755)
        print("✓ dev/ops tools configured")

    def disable_services(self) -> None:
        for service in DISABLE_SERVICES:
            run(["systemctl", "disable", service])
            run(["systemctl", "stop", service])
        run(["systemctl", "enable", "--now", "irqbalance"])
        print("✓ unnecessary services disabled")

    def run_common(self) -> None:
        self.configure_timezone()
        self.configure_locale()
        self.configure_sysctl()
        self.configure_limits()
        self.configure_network()
        self.configure_filesystem()
        self.configure_memory()
        self.configure_io()
        self.configure_firewall()
        self.configure_selinux()
        self.configure_ntp()
        self.configure_tuned()
        self.configure_cpufreq()
        self.configure_tools()
        if os.environ.get("SKIP_NODE_EXPORTER") != "1":
            krun_install.install_node_exporter()
        self.disable_services()
        run(["sysctl", "-p", "/etc/sysctl.d/99-system.conf"])
        run(["sysctl", "-p", "/etc/sysctl.d/99-docker.conf"], check=False)
        print("✓ system init and performance tuning done, reboot recommended")

    def run_rhel(self) -> None:
        print(f"initializing {self.distro_id or 'rhel'} {self.distro_version}")
        self.check_rhel_version()
        self.backup_configs()
        self.install_packages_rhel()
        self.run_common()

    def run_debian(self) -> None:
        print(f"initializing {self.distro_id or 'debian'} {self.distro_version}")
        self.check_debian_version()
        self.backup_configs()
        self.install_packages_debian()
        self.run_common()

    def run(self) -> None:
        self.check_root()
        platform = self.platform()
        if platform == "mac":
            print("✗ macOS not supported for system init")
            sys.exit(1)
        if platform == "rhel":
            self.run_rhel()
            return
        if platform == "debian":
            self.run_debian()
            return
        print(f"✗ unsupported platform: {platform}")
        sys.exit(1)


def main() -> None:
    SystemInit().run()


if __name__ == "__main__":
    main()
