#!/usr/bin/env python3
# Copyright (c) 2026 kk
# MIT License - shared helpers for krun python scripts

from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = "kevin197011/krun"
RAW = f"https://raw.githubusercontent.com/{REPO}/main/lib/py/scripts"


def has_cmd(name: str) -> bool:
    return shutil.which(name) is not None


def docker_running() -> bool:
    if has_cmd("systemctl"):
        proc = subprocess.run(
            ["systemctl", "is-active", "--quiet", "docker"],
            check=False,
        )
        if proc.returncode == 0:
            return True
    if has_cmd("docker"):
        proc = subprocess.run(["docker", "info"], capture_output=True, check=False)
        return proc.returncode == 0
    return False


def docker_present() -> bool:
    """Docker installed or running — used to avoid breaking container networking."""
    if docker_running():
        return True
    if has_cmd("docker"):
        return True
    if Path("/usr/bin/docker").is_file() or Path("/usr/local/bin/docker").is_file():
        return True
    if has_cmd("systemctl"):
        proc = subprocess.run(
            ["systemctl", "list-unit-files", "docker.service"],
            capture_output=True,
            text=True,
            check=False,
        )
        if "docker.service" in proc.stdout:
            return True
    return False


def platform() -> str:
    if sys.platform == "darwin":
        return "mac"
    if has_cmd("dnf") or has_cmd("yum"):
        return "rhel"
    if has_cmd("apt-get"):
        return "deb"
    return "unknown"


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


def require_root() -> None:
    if sys.platform != "darwin" and os.geteuid() != 0:
        print("✗ must run as root")
        sys.exit(1)


def run(
    cmd: list[str] | str,
    *,
    check: bool = False,
    env: dict[str, str] | None = None,
    shell: bool | None = None,
) -> int:
    use_shell = isinstance(cmd, str) if shell is None else shell
    if use_shell:
        return subprocess.run(cmd, shell=True, check=check, env=env).returncode
    return subprocess.run(cmd, check=check, env=env).returncode


def run_ok(cmd: list[str] | str, *, env: dict[str, str] | None = None) -> bool:
    return run(cmd, env=env) == 0


def write_if_changed(path: Path, content: str, mode: int = 0o644) -> bool:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.is_file() and path.read_text(encoding="utf-8") == content:
        print(f"✓ {path} unchanged, skip")
        return False
    path.write_text(content, encoding="utf-8")
    path.chmod(mode)
    print(f"✓ {path} updated")
    return True


def ensure_line(path: Path, line: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    text = path.read_text(encoding="utf-8") if path.is_file() else ""
    if line not in text:
        with path.open("a", encoding="utf-8") as handle:
            handle.write(f"{line}\n")


def service_enable(name: str) -> None:
    run(["systemctl", "enable", name])
    run(["systemctl", "restart", name])


def service_enabled(name: str) -> bool:
    proc = subprocess.run(["systemctl", "is-enabled", name], capture_output=True, text=True, check=False)
    return proc.stdout.strip() in {"enabled", "static"}


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
        if not brew:
            print("✗ not supported on macOS")
            sys.exit(1)
        require_root() if False else None
        if not has_cmd("brew"):
            print("✗ Homebrew required")
            sys.exit(1)
        run(["brew", "install", *brew])
    elif plat == "rhel":
        require_root()
        pm = pm_rhel()
        if epel:
            run([pm, "install", "-y", "epel-release"])
        pkgs = rhel or deb or []
        run([pm, "install", "-y", *pkgs])
    elif plat == "deb":
        require_root()
        env = {**os.environ, "DEBIAN_FRONTEND": "noninteractive"}
        run(["apt-get", "update"], env=env)
        run(["apt-get", "install", "-y", *(deb or rhel or [])], env=env)
    else:
        print(f"✗ unsupported platform: {plat}")
        sys.exit(1)

    if service and plat != "mac":
        if service_enabled(service):
            print(f"✓ {service} already enabled, skip")
        else:
            service_enable(service)
            print(f"✓ {service} enabled")


def curl_pipe(url: str, shell: str = "bash") -> None:
    require_root()
    proc = subprocess.run(["curl", "-fsSL", url], capture_output=True, check=False)
    if proc.returncode != 0:
        print(f"✗ curl failed: {url}")
        sys.exit(1)
    with tempfile.NamedTemporaryFile(mode="wb", delete=False) as tmp:
        tmp.write(proc.stdout)
        path = tmp.name
    os.chmod(path, 0o755)
    subprocess.run([shell, path], check=False)


def _linux_arch() -> str:
    machine = os.uname().machine.lower()
    if machine in {"x86_64", "amd64"}:
        return "amd64"
    if machine in {"aarch64", "arm64"}:
        return "arm64"
    return machine


def _pick_tarball_url(
    repo: str, release: dict, binary: str, arch: str, asset_filter: str | None,
) -> str | None:
    hint = (asset_filter or binary).lower()
    arch_l = arch.lower()
    for asset in release.get("assets", []):
        name = asset.get("name", "")
        lower = name.lower()
        if not lower.endswith(".tar.gz"):
            continue
        if "linux" not in lower:
            continue
        if arch_l not in lower:
            continue
        if hint not in lower:
            continue
        return asset["browser_download_url"]

    tag = release.get("tag_name", "").lstrip("v")
    if not tag:
        return None
    name = asset_filter or binary
    for pattern in (
        f"https://github.com/{repo}/releases/download/v{tag}/{name}-{tag}.linux-{arch}.tar.gz",
        f"https://github.com/{repo}/releases/download/v{tag}/{name}_{tag}_Linux_{arch}.tar.gz",
        f"https://github.com/{repo}/releases/download/v{tag}/{name}_Linux_{arch}.tar.gz",
    ):
        proc = subprocess.run(["curl", "-fsI", pattern], capture_output=True, check=False)
        if proc.returncode == 0 and b" 200" in proc.stdout:
            return pattern
    return None


def _download_url(url: str, dest: Path) -> bool:
    if run_ok(["curl", "-fsSL", url, "-o", str(dest)]):
        return True
    mirror = f"https://ghproxy.com/{url}"
    return run(["curl", "-fsSL", mirror, "-o", str(dest)]) == 0


def github_binary(
    repo: str,
    binary: str,
    dest: str = "/usr/local/bin",
    asset_filter: str | None = None,
) -> None:
    require_root()
    api = f"https://api.github.com/repos/{repo}/releases/latest"
    proc = subprocess.run(["curl", "-fsSL", api], capture_output=True, text=True, check=False)
    if proc.returncode != 0:
        print(f"✗ cannot fetch release info for {repo}")
        sys.exit(1)
    import json

    release = json.loads(proc.stdout)
    arch = _linux_arch()
    url = _pick_tarball_url(repo, release, binary, arch, asset_filter)
    if not url:
        print(f"✗ no linux/{arch} tarball found for {repo} ({binary})")
        sys.exit(1)

    archive = Path("/tmp/krun-dl.tar.gz")
    if not _download_url(url, archive):
        print(f"✗ cannot download {url}")
        sys.exit(1)
    if archive.read_bytes()[:2] != b"\x1f\x8b":
        print(f"✗ downloaded file is not a valid tarball: {url}")
        sys.exit(1)

    tmpdir = Path(tempfile.mkdtemp(prefix="krun-dl-"))
    dest_path = Path(dest) / binary
    try:
        if run(["tar", "-xzf", str(archive), "-C", str(tmpdir)]) != 0:
            print(f"✗ cannot extract {archive}")
            sys.exit(1)
        matches = [p for p in tmpdir.rglob(binary) if p.is_file() and p.name == binary]
        if not matches:
            print(f"✗ {binary} not found in release tarball")
            sys.exit(1)
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        service = f"{binary}.service"
        if dest_path.is_file() and has_cmd("systemctl"):
            proc = subprocess.run(["systemctl", "is-active", "--quiet", service], check=False)
            if proc.returncode == 0:
                print(f"stopping {service} for binary update")
                run(["systemctl", "stop", service])
        shutil.copy2(matches[0], dest_path)
        dest_path.chmod(0o755)
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)

    if not dest_path.is_file():
        print(f"✗ failed to install {binary}")
        sys.exit(1)
    print(f"✓ installed {binary} to {dest_path}")


def script_header(name: str, *, sudo: bool = False) -> str:
    pipe = f"curl -fsSL {RAW}/{name}.py"
    if sudo:
        pipe += " | sudo python3"
    else:
        pipe += " | python3"
    return f"""#!/usr/bin/env python3
# Copyright (c) 2026 kk
# MIT License
# curl exec:
# {pipe}
# idempotent: safe to re-run

from krun.registry import run_script

if __name__ == "__main__":
    run_script("{name}")
"""
