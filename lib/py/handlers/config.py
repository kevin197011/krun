"""Config tasks."""

from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path

from krun_common import (
    ensure_line,
    platform,
    read_os_release,
    require_root,
    run,
    service_enable,
    service_enabled,
    write_if_changed,
)

ROCKY_REPO = """\
[baseos]
name=Rocky Linux $releasever - BaseOS
baseurl=http://mirrors.tuna.tsinghua.edu.cn/rocky/$releasever/BaseOS/$basearch/os/
enabled=1
gpgcheck=0

[appstream]
name=Rocky Linux $releasever - AppStream
baseurl=http://mirrors.tuna.tsinghua.edu.cn/rocky/$releasever/AppStream/$basearch/os/
enabled=1
gpgcheck=0

[extras]
name=Rocky Linux $releasever - Extras
baseurl=http://mirrors.tuna.tsinghua.edu.cn/rocky/$releasever/extras/$basearch/os/
enabled=1
gpgcheck=0
"""

CENTOS7_REPO = """\
[base]
name=CentOS-7 - Base
baseurl=http://mirrors.tuna.tsinghua.edu.cn/centos/7/os/$basearch/
gpgcheck=0
enabled=1

[updates]
name=CentOS-7 - Updates
baseurl=http://mirrors.tuna.tsinghua.edu.cn/centos/7/updates/$basearch/
gpgcheck=0
enabled=1

[extras]
name=CentOS-7 - Extras
baseurl=http://mirrors.tuna.tsinghua.edu.cn/centos/7/extras/$basearch/
gpgcheck=0
enabled=1
"""


def config_rpm_repo(variant: str) -> None:
    require_root()
    if platform() != "rhel":
        print("✗ rpm repo config is for RHEL family only")
        raise SystemExit(1)
    content = ROCKY_REPO if variant == "rocky" else CENTOS7_REPO
    fname = "rocky.repo" if variant == "rocky" else "centos7.repo"
    backup = Path("/etc/yum.repos.d/backup")
    backup.mkdir(parents=True, exist_ok=True)
    write_if_changed(Path(f"/etc/yum.repos.d/{fname}"), content)
    pm = "dnf" if __import__("shutil").which("dnf") else "yum"
    run([pm, "clean", "all"])
    run([pm, "makecache"])
    print(f"✓ {variant} repo configured")


def config_timezone() -> None:
    tz = os.environ.get("SYSTEM_TIMEZONE", "Asia/Hong_Kong")
    require_root()
    if __import__("shutil").which("timedatectl"):
        proc = subprocess.run(["timedatectl", "show", "-p", "Timezone", "--value"], capture_output=True, text=True)
        if proc.stdout.strip() == tz:
            print("✓ timezone already set, skip")
            return
        run(["timedatectl", "set-timezone", tz])
    else:
        Path("/etc/localtime").unlink(missing_ok=True)
        Path("/etc/localtime").symlink_to(f"/usr/share/zoneinfo/{tz}")
    print(f"✓ timezone {tz}")


def config_locale() -> None:
    locale = os.environ.get("SYSTEM_LOCALE", "en_US.UTF-8")
    require_root()
    if __import__("shutil").which("localectl"):
        run(["localectl", "set-locale", f"LANG={locale}"])
    write_if_changed(Path("/etc/locale.conf"), f"LANG={locale}\nLC_ALL={locale}\n")
    print(f"✓ locale {locale}")


def config_proxy() -> None:
    host = os.environ.get("PROXY_HOST", "10.170.1.19")
    port = os.environ.get("PROXY_PORT", "8888")
    url = f"http://{host}:{port}"
    if __import__("sys").stdin.isatty():
        for key in ("http_proxy", "https_proxy", "HTTP_PROXY", "HTTPS_PROXY"):
            os.environ[key] = url
        print(f"✓ proxy applied: {url}")
    else:
        print(f'export http_proxy="{url}"')
        print(f'export https_proxy="{url}"')


def disable_firewall_selinux() -> None:
    require_root()
    if __import__("shutil").which("firewall-cmd"):
        run(["systemctl", "stop", "firewalld"])
        run(["systemctl", "disable", "firewalld"])
        print("✓ firewalld disabled")
    if __import__("shutil").which("ufw"):
        run(["ufw", "--force", "disable"])
        print("✓ ufw disabled")
    selinux = Path("/etc/selinux/config")
    if selinux.is_file() and not re.search(r"^SELINUX=disabled", selinux.read_text(), re.M):
        write_if_changed(selinux, re.sub(r"^SELINUX=.*", "SELINUX=disabled", selinux.read_text(), flags=re.M))
        run(["setenforce", "0"])
        print("✓ SELinux disabled")
    elif selinux.is_file():
        print("✓ SELinux already disabled, skip")


def config_ssh_harden() -> None:
    require_root()
    sshd = Path("/etc/ssh/sshd_config")
    if not sshd.is_file():
        print("✗ sshd_config not found")
        return
    text = sshd.read_text(encoding="utf-8")
    for pattern, repl in (
        (r"^#?PermitRootLogin.*", "PermitRootLogin no"),
        (r"^#?PasswordAuthentication.*", "PasswordAuthentication no"),
        (r"^#?MaxAuthTries.*", "MaxAuthTries 3"),
    ):
        text = re.sub(pattern, repl, text, flags=re.M)
    write_if_changed(sshd, text)
    run(["sshd", "-t"])
    run(["systemctl", "restart", "sshd"])
    print("✓ ssh hardened")


def config_ssh_keys() -> None:
    key = os.environ.get("SSH_PUBLIC_KEY", "")
    if not key and Path(os.environ.get("SSH_KEY_FILE", "")).is_file():
        key = Path(os.environ["SSH_KEY_FILE"]).read_text(encoding="utf-8").strip()
    if not key:
        print("✗ set SSH_PUBLIC_KEY or SSH_KEY_FILE")
        raise SystemExit(1)
    user = os.environ.get("SSH_USER", "root")
    auth = Path(f"/home/{user}/.ssh/authorized_keys") if user != "root" else Path("/root/.ssh/authorized_keys")
    auth.parent.mkdir(parents=True, exist_ok=True)
    if auth.is_file() and key in auth.read_text(encoding="utf-8"):
        print("✓ ssh key exists, skip")
        return
    ensure_line(auth, key)
    auth.chmod(0o600)
    print("✓ ssh key added")


def config_disk_data() -> None:
    require_root()
    disk = os.environ.get("data_disk", "/dev/sdb")
    mount = os.environ.get("mount_point", "/data")
    fstype = os.environ.get("fs_type", "xfs")
    if disk in {"/", "/dev/sda"}:
        print("✗ system disk, abort")
        raise SystemExit(1)
    if not Path(disk).is_block_device():
        print(f"✗ disk not found: {disk}")
        raise SystemExit(1)
    Path(mount).mkdir(parents=True, exist_ok=True)
    if run(["blkid", disk]) != 0:
        print(f"formatting {disk}")
        run(["mkfs.xfs", "-f", disk] if fstype == "xfs" else ["mkfs.ext4", "-F", disk])
    else:
        print("✓ filesystem exists, skip mkfs")
    proc = subprocess.run(["blkid", "-s", "UUID", "-o", "value", disk], capture_output=True, text=True)
    uuid = proc.stdout.strip()
    if not uuid:
        print("✗ no UUID")
        raise SystemExit(1)
    fstab = Path("/etc/fstab")
    line = f"UUID={uuid} {mount} {fstype} defaults 0 0"
    if fstab.is_file() and uuid in fstab.read_text(encoding="utf-8"):
        print("✓ fstab entry exists, skip")
    else:
        ensure_line(fstab, line)
        print("✓ fstab updated")
    if subprocess.run(["mountpoint", "-q", mount]).returncode != 0:
        run(["mount", disk, mount])
        print(f"✓ mounted {mount}")
    else:
        print("✓ already mounted")
    Path(f"{mount}/record").mkdir(parents=True, exist_ok=True)
    print("✓ disk data mount done")


def config_fstab_guide() -> None:
    require_root()
    print("current fstab:")
    run(["cat", "/etc/fstab"])
    print("current mounts:")
    run(["df", "-h"])
    print("use config_disk_data for automated data disk setup")


def config_git_global() -> None:
    run(["git", "config", "--global", "init.defaultBranch", "main"])
    run(["git", "config", "--global", "core.editor", "vim"])
    run(["git", "config", "--global", "color.ui", "auto"])
    print("✓ git global config")


def reset_git_history() -> None:
    branch = os.environ.get("target_branch", "main")
    msg = os.environ.get("commit_message", "Initial commit")
    if not run(["git", "rev-parse", "--git-dir"], check=False) == 0:
        print("✗ not a git repo")
        raise SystemExit(1)
    run(["git", "checkout", branch])
    run(f'git reset "$(git commit-tree HEAD^{{tree}} -m "{msg}")"', shell=True)
    run(["git", "push", "origin", branch, "--force"])
    print("✓ git history reset")
