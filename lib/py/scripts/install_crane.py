#!/usr/bin/env python3
# Copyright (c) 2026 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/scripts/install_crane.py | sudo python3
#
# idempotent: check state before each change; safe to re-run

from __future__ import annotations

import json
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


def _linux_arch() -> str:
    machine = os.uname().machine.lower()
    if machine in {"x86_64", "amd64"}:
        return "amd64"
    if machine in {"aarch64", "arm64"}:
        return "arm64"
    return machine


def github_binary(repo: str, binary: str, dest: str = "/usr/local/bin") -> None:
    """Download latest Linux release asset matching binary and install to dest."""
    require_root()
    api = f"https://api.github.com/repos/{repo}/releases/latest"
    proc = subprocess.run(["curl", "-fsSL", api], capture_output=True, text=True, check=False)
    if proc.returncode != 0:
        print(f"✗ cannot fetch release info for {repo}")
        raise SystemExit(1)
    release = json.loads(proc.stdout)
    arch = _linux_arch()
    url = None
    for asset in release.get("assets", []):
        name = asset.get("name", "").lower()
        if not name.endswith((".tar.gz", ".tgz")):
            continue
        if "linux" not in name:
            continue
        if arch not in name:
            continue
        if binary.lower() not in name and binary.lower().replace("_", "") not in name.replace("_", ""):
            # helm/crane naming varies; still accept if arch+linux match and hint soft
            if binary == "crane" and "go-containerregistry" not in name and "crane" not in name:
                continue
            if binary != "crane" and binary.lower() not in name:
                continue
        url = asset["browser_download_url"]
        break
    if not url:
        # fallback patterns
        tag = release.get("tag_name", "").lstrip("v")
        candidates = [
            f"https://github.com/{repo}/releases/download/v{tag}/{binary}-{tag}.linux-{arch}.tar.gz",
            f"https://github.com/{repo}/releases/download/v{tag}/{binary}_{tag}_Linux_{arch}.tar.gz",
            f"https://github.com/{repo}/releases/download/v{tag}/{binary}_Linux_{arch}.tar.gz",
            f"https://github.com/{repo}/releases/download/{release.get('tag_name', tag)}/{binary}_{release.get('tag_name', tag).lstrip('v')}_linux_{arch}.tar.gz",
        ]
        for c in candidates:
            if run(["curl", "-fsI", c], check=False) == 0:
                url = c
                break
    if not url:
        print(f"✗ no linux/{arch} archive for {repo} ({binary})")
        raise SystemExit(1)
    archive = Path("/tmp/krun-dl.tar.gz")
    run(["curl", "-fsSL", url, "-o", str(archive)])
    tmpdir = Path(tempfile.mkdtemp(prefix="krun-dl-"))
    try:
        run(["tar", "-xzf", str(archive), "-C", str(tmpdir)])
        matches = [p for p in tmpdir.rglob(binary) if p.is_file() and p.name == binary]
        if not matches:
            print(f"✗ {binary} not found in archive")
            raise SystemExit(1)
        dest_path = Path(dest) / binary
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(matches[0], dest_path)
        dest_path.chmod(0o755)
        print(f"✓ installed {binary} to {dest_path}")
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)

def install_github_tool(tool: str) -> None:
    mapping = {
        "k9s": ("derailed/k9s", "k9s"),
        "helm": ("helm/helm", "helm"),
        "crane": ("google/go-containerregistry", "crane"),
        "rclone": ("rclone/rclone", "rclone"),
    }
    repo, binary = mapping[tool]
    github_binary(repo, binary)




def common() -> None:
    install_github_tool('crane')


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
