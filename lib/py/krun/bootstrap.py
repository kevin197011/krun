#!/usr/bin/env python3
"""Stage-2 bootstrap: download/sync full krun package into cache."""

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
    "krun/prefetch.py",
    "krun/entry.py",
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
    return remote != _read_version(CACHE / VERSION_FILE)


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
    stale = _cache_stale()
    if stale and (CACHE / "krun").is_dir():
        shutil.rmtree(CACHE / "krun", ignore_errors=True)

    for rel in FILES:
        dest = CACHE / rel
        if dest.is_file() and not stale:
            continue
        try:
            _fetch(f"{BASE}/{rel}", dest)
        except OSError as exc:
            print(f"✗ bootstrap failed: {BASE}/{rel} ({exc})")
            raise SystemExit(1) from exc

    path = str(CACHE)
    if path not in sys.path:
        sys.path.insert(0, path)
