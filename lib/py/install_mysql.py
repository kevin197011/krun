#!/usr/bin/env python3
# Copyright (c) 2026 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/install_mysql.py | sudo python3
#
# idempotent: check state before each change; safe to re-run

from __future__ import annotations

import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

_UA = "Mozilla/5.0 (compatible; krun/2.1)"


def has_cmd(name: str) -> bool:
    return shutil.which(name) is not None


def platform() -> str:
    if sys.platform == "darwin":
        return "mac"
    if has_cmd("dnf") or has_cmd("yum"):
        return "centos"
    if has_cmd("apt-get"):
        return "debian"
    return "unknown"


def read_os_release() -> dict[str, str]:
    data: dict[str, str] = {}
    path = Path("/etc/os-release")
    if not path.is_file():
        return data
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if "=" not in line:
            continue
        k, v = line.split("=", 1)
        data[k] = v.strip().strip('"')
    return data


def require_root() -> None:
    if hasattr(os, "geteuid") and os.geteuid() != 0:
        print("✗ please run as root")
        raise SystemExit(1)


def run(cmd: list[str] | str, *, check: bool = True, shell: bool = False, env: dict[str, str] | None = None) -> int:
    print(f"+ {cmd if isinstance(cmd, str) else ' '.join(cmd)}")
    proc = subprocess.run(cmd, check=False, shell=shell, env=env)
    if check and proc.returncode != 0:
        raise SystemExit(proc.returncode)
    return proc.returncode


def run_ok(cmd: list[str] | str, *, env: dict[str, str] | None = None) -> bool:
    return run(cmd, check=False, shell=isinstance(cmd, str), env=env) == 0


def write_if_changed(path: Path, content: str, mode: int = 0o644) -> bool:
    path = Path(path)
    if path.is_file() and path.read_text(encoding="utf-8", errors="replace") == content:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    path.chmod(mode)
    return True


def ensure_line(path: Path, line: str) -> None:
    path = Path(path)
    text = path.read_text(encoding="utf-8", errors="replace") if path.is_file() else ""
    if line not in text.splitlines():
        with path.open("a", encoding="utf-8") as fh:
            fh.write(line + "\n")


def service_enable(name: str) -> None:
    run(["systemctl", "daemon-reload"], check=False)
    run(["systemctl", "enable", "--now", name], check=False)


def pm_rhel() -> str:
    return "dnf" if has_cmd("dnf") else "yum"


def install_packages(
    *,
    deb: list[str] | None = None,
    rhel: list[str] | None = None,
    brew: list[str] | None = None,
    service: str | None = None,
    epel: bool = False,
) -> None:
    plat = platform()
    if plat == "mac":
        pkgs = brew or deb or rhel or []
        if not pkgs:
            return
        if not has_cmd("brew"):
            print("✗ brew required on macOS")
            raise SystemExit(1)
        run(["brew", "install", *pkgs], check=False)
    elif plat == "debian":
        require_root()
        pkgs = deb or []
        env = {**os.environ, "DEBIAN_FRONTEND": "noninteractive"}
        run(["apt-get", "update"], env=env, check=False)
        if pkgs:
            run(["apt-get", "install", "-y", *pkgs], env=env)
    elif plat == "centos":
        require_root()
        pkgs = rhel or []
        pm = pm_rhel()
        if epel:
            run([pm, "install", "-y", "epel-release"], check=False)
        if pkgs:
            run([pm, "install", "-y", *pkgs])
    else:
        print(f"✗ unsupported platform: {plat}")
        raise SystemExit(1)
    if service:
        service_enable(service)


def _curl(url: str, dest: str | None = None) -> None:
    cmd = ["curl", "-fsSL", url]
    if dest:
        cmd.extend(["-o", dest])
        run(cmd)
    else:
        run(cmd)


def curl_pipe(url: str, shell: str = "bash") -> None:
    require_root()
    run(f"curl -fsSL {shlex.quote(url)} | {shell}", shell=True)


def curl_shell(url: str, *, head: bool = False, output: str | None = None) -> str:
    parts = ["curl", "-fsSL"]
    if head:
        parts.append("-I")
    parts.append(shlex.quote(url))
    if output:
        parts.extend(["-o", shlex.quote(output)])
    return " ".join(parts)


def install_mysql() -> None:
    """Install MySQL 8.4 LTS from the official community repo."""
    plat = platform()
    if plat == "mac":
        run(["brew", "install", "mysql@8.4"])
        run(["brew", "services", "start", "mysql@8.4"], check=False)
        print("✓ MySQL 8.4 installed via Homebrew")
        return

    require_root()
    if run_ok("mysqld --version 2>/dev/null | grep -q 'Ver 8.'"):
        print("✓ MySQL 8 already installed")
        _mysql_enable()
        return

    if plat == "rhel":
        osr = read_os_release()
        major = osr.get("VERSION_ID", "9").split(".", 1)[0]
        rpms = {
            "7": "https://repo.mysql.com/mysql84-community-release-el7-1.noarch.rpm",
            "8": "https://repo.mysql.com/mysql84-community-release-el8-1.noarch.rpm",
            "9": "https://repo.mysql.com/mysql84-community-release-el9-1.noarch.rpm",
        }
        url = rpms.get(major)
        if not url:
            print(f"✗ unsupported RHEL major: {major}")
            raise SystemExit(1)
        pm = pm_rhel()
        run("rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 || true", shell=True)
        run("rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2025 || true", shell=True)
        run(f"{pm} module disable -y mysql >/dev/null 2>&1 || true", shell=True)
        run([pm, "install", "-y", url])
        run([pm, "install", "-y", "mysql-community-server", "mysql-community-client"])
    elif plat == "deb":
        osr = read_os_release()
        family = "ubuntu" if osr.get("ID") == "ubuntu" or "ubuntu" in osr.get("ID_LIKE", "") else "debian"
        codename = osr.get("VERSION_CODENAME", "")
        if not codename:
            print("✗ cannot read VERSION_CODENAME")
            raise SystemExit(1)
        env = {**os.environ, "DEBIAN_FRONTEND": "noninteractive"}
        run(["apt-get", "update"], env=env)
        run(["apt-get", "install", "-y", "ca-certificates", "curl", "gnupg"], env=env)
        run(
            "install -d /usr/share/keyrings && "
            "curl -fsSL https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 | gpg --dearmor -o /usr/share/keyrings/mysql-2023.gpg && "
            "curl -fsSL https://repo.mysql.com/RPM-GPG-KEY-mysql-2025 | gpg --dearmor -o /usr/share/keyrings/mysql-2025.gpg && "
            "cat /usr/share/keyrings/mysql-2023.gpg /usr/share/keyrings/mysql-2025.gpg > /usr/share/keyrings/mysql.gpg && "
            f'echo "deb [signed-by=/usr/share/keyrings/mysql.gpg] https://repo.mysql.com/apt/{family} {codename} mysql-8.4-lts" '
            "> /etc/apt/sources.list.d/mysql.list",
            shell=True,
        )
        run(["apt-get", "update"], env=env)
        run(["apt-get", "install", "-y", "mysql-community-server", "mysql-community-client"], env=env)
    else:
        print("✗ mysql install supports deb/rhel/mac only")
        raise SystemExit(1)
    _mysql_enable()
    print("✓ MySQL 8.4 LTS installed")



def _mysql_enable() -> None:
    import subprocess

    listed = subprocess.run(
        ["systemctl", "list-unit-files", "mysql.service", "mysqld.service"],
        capture_output=True, text=True, check=False,
    ).stdout
    svc = "mysql" if "mysql.service" in listed and "mysqld.service" not in listed else "mysqld"
    if "mysqld.service" in listed:
        svc = "mysqld"
    elif "mysql.service" in listed:
        svc = "mysql"
    service_enable(svc)
    print(f"✓ MySQL service {svc} enabled")
    log = subprocess.run(
        "grep -h 'temporary password' /var/log/mysqld.log /var/log/mysql/error.log 2>/dev/null | tail -1",
        shell=True, capture_output=True, text=True, check=False,
    )
    line = log.stdout.strip()
    if line:
        print(line)
    password = os.environ.get("MYSQL_ROOT_PASSWORD", "")
    if not password:
        print("  mysql -uroot -p")
        return
    if not line:
        print("⚠ MYSQL_ROOT_PASSWORD set but no temporary password in the log")
        return
    tmp = line.split()[-1]
    ok = run([
        "mysql", "--connect-expired-password", "-uroot", f"-p{tmp}", "-e",
        f"ALTER USER 'root'@'localhost' IDENTIFIED BY '{password}';",
    ])
    print("✓ root password updated" if ok == 0 else "⚠ failed to set MYSQL_ROOT_PASSWORD")



def common() -> None:
    install_mysql()


def centos() -> None:
    common()


def debian() -> None:
    common()


def mac() -> None:
    common()


def run_script() -> None:
    plat = platform()
    if plat == "mac":
        mac()
    elif plat == "centos":
        centos()
    elif plat == "debian":
        debian()
    else:
        print(f"✗ unsupported platform: {plat}")
        raise SystemExit(1)


def main() -> None:
    run_script()


if __name__ == "__main__":
    main()
