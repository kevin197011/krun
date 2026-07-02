#!/usr/bin/env python3
"""Cache krun package for curl-piped script execution."""

from __future__ import annotations

import os
import shutil
import sys
import urllib.request
from pathlib import Path

BASE = os.environ.get(
    "KRUN_PY_BASE",
    "https://raw.githubusercontent.com/kevin197011/krun/main/lib/py",
)
CACHE = Path(os.environ.get("KRUN_PY_CACHE", Path.home() / ".cache/krun/py"))
UA = "krun/2.1"
VERSION_FILE = "krun/VERSION"

FILES = [
    "krun/__init__.py",
    VERSION_FILE,
    "krun/bootstrap.py",
    "krun/common.py",
    "krun/registry.py",
    "krun/handlers/__init__.py",
    "krun/handlers/install.py",
    "krun/handlers/config.py",
    "krun/handlers/ops.py",
    "krun/handlers/network.py",
    "krun/handlers/system.py",
]

# Inlined in scripts/*.py — curl | python3 has no local krun package.
LOADER = """
import os, sys, urllib.request
from pathlib import Path

def _krun_fetch_version(base):
    try:
        req = urllib.request.Request(f"{base}/krun/VERSION", headers={"User-Agent": "krun/2.1"})
        return urllib.request.urlopen(req, timeout=30).read().decode().strip()
    except OSError:
        return ""

def _krun_bootstrap_path():
    base = os.environ.get("KRUN_PY_BASE", "https://raw.githubusercontent.com/kevin197011/krun/main/lib/py")
    cache = Path(os.environ.get("KRUN_PY_CACHE", Path.home() / ".cache/krun/py"))
    try:
        here = Path(__file__).resolve().parent
        for root in (here, here.parent):
            if (root / "krun" / "bootstrap.py").is_file():
                if str(root) not in sys.path:
                    sys.path.insert(0, str(root))
                return
    except NameError:
        pass
    cache.mkdir(parents=True, exist_ok=True)
    remote_ver = _krun_fetch_version(base)
    ver_path = cache / "krun" / "VERSION"
    cached_ver = ver_path.read_text(encoding="utf-8").strip() if ver_path.is_file() else ""
    stale = bool(os.environ.get("KRUN_REFRESH")) or (remote_ver and remote_ver != cached_ver)
    if stale and (cache / "krun").is_dir():
        import shutil
        shutil.rmtree(cache / "krun", ignore_errors=True)
    dest = cache / "krun" / "bootstrap.py"
    dest.parent.mkdir(parents=True, exist_ok=True)
    if not dest.is_file() or stale:
        req = urllib.request.Request(f"{base}/krun/bootstrap.py", headers={"User-Agent": "krun/2.1"})
        dest.write_bytes(urllib.request.urlopen(req, timeout=120).read())
    if str(cache) not in sys.path:
        sys.path.insert(0, str(cache))

_krun_bootstrap_path()
""".strip()


def _fetch(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    dest.write_bytes(urllib.request.urlopen(req, timeout=120).read())


def _read_version(path: Path) -> str:
    if not path.is_file():
        return ""
    return path.read_text(encoding="utf-8").strip()


def _remote_version() -> str:
    try:
        req = urllib.request.Request(f"{BASE}/{VERSION_FILE}", headers={"User-Agent": UA})
        return urllib.request.urlopen(req, timeout=30).read().decode().strip()
    except OSError:
        return ""


def _cache_stale() -> bool:
    if os.environ.get("KRUN_REFRESH"):
        return True
    remote = _remote_version()
    if not remote:
        return False
    cached = _read_version(CACHE / VERSION_FILE)
    return remote != cached


def setup() -> None:
    try:
        root = Path(__file__).resolve().parent.parent  # lib/py
    except NameError:
        root = None

    if root and (root / "krun" / "registry.py").is_file():
        path = str(root)
        if path not in sys.path:
            sys.path.insert(0, path)
        return

    CACHE.mkdir(parents=True, exist_ok=True)
    if _cache_stale() and (CACHE / "krun").is_dir():
        shutil.rmtree(CACHE / "krun", ignore_errors=True)

    for rel in FILES:
        dest = CACHE / rel
        if dest.is_file() and not _cache_stale():
            continue
        url = f"{BASE}/{rel}"
        try:
            _fetch(url, dest)
        except OSError as exc:
            print(f"✗ bootstrap failed: {url} ({exc})")
            raise SystemExit(1) from exc
    path = str(CACHE)
    if path not in sys.path:
        sys.path.insert(0, path)
