#!/usr/bin/env python3
"""Stage-1 bootstrap: put krun on sys.path before any krun import (curl | python3)."""

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


def _fetch_version(base: str) -> str:
    try:
        req = urllib.request.Request(f"{base}/krun/VERSION", headers={"User-Agent": UA})
        return urllib.request.urlopen(req, timeout=30).read().decode().strip()
    except OSError:
        return ""


def prefetch_path() -> None:
    """Ensure sys.path contains lib/py (local) or ~/.cache/krun/py (remote)."""
    try:
        here = Path(__file__).resolve().parent
        for root in (here.parent, here.parent.parent):
            if (root / "krun" / "bootstrap.py").is_file():
                path = str(root)
                if path not in sys.path:
                    sys.path.insert(0, path)
                return
    except NameError:
        pass

    base = BASE
    cache = CACHE
    cache.mkdir(parents=True, exist_ok=True)
    remote_ver = _fetch_version(base)
    ver_path = cache / "krun" / "VERSION"
    cached_ver = ver_path.read_text(encoding="utf-8").strip() if ver_path.is_file() else ""
    stale = bool(os.environ.get("KRUN_REFRESH")) or (remote_ver and remote_ver != cached_ver)
    if stale and (cache / "krun").is_dir():
        shutil.rmtree(cache / "krun", ignore_errors=True)

    dest = cache / "krun" / "bootstrap.py"
    dest.parent.mkdir(parents=True, exist_ok=True)
    if not dest.is_file() or stale:
        req = urllib.request.Request(f"{base}/krun/bootstrap.py", headers={"User-Agent": UA})
        dest.write_bytes(urllib.request.urlopen(req, timeout=120).read())
    path = str(cache)
    if path not in sys.path:
        sys.path.insert(0, path)


# Inlined into scripts/*.py — must run before `from krun...`
INLINE = """
import os, sys, urllib.request
from pathlib import Path

def _krun_prefetch():
    base = os.environ.get("KRUN_PY_BASE", "https://raw.githubusercontent.com/kevin197011/krun/main/lib/py")
    cache = Path(os.environ.get("KRUN_PY_CACHE", Path.home() / ".cache/krun/py"))
    try:
        here = Path(__file__).resolve().parent
        for root in (here.parent, here):
            if (root / "krun" / "bootstrap.py").is_file():
                if str(root) not in sys.path:
                    sys.path.insert(0, str(root))
                return
    except NameError:
        pass
    cache.mkdir(parents=True, exist_ok=True)
    try:
        req = urllib.request.Request(f"{base}/krun/VERSION", headers={"User-Agent": "krun/2.1"})
        remote_ver = urllib.request.urlopen(req, timeout=30).read().decode().strip()
    except OSError:
        remote_ver = ""
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

_krun_prefetch()
""".strip()
