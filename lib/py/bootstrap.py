#!/usr/bin/env python3
"""Cache lib/py modules for curl-piped single-file execution."""

from __future__ import annotations

import os
import sys
import urllib.request
from pathlib import Path

BASE = os.environ.get(
    "KRUN_PY_BASE",
    "https://raw.githubusercontent.com/kevin197011/krun/main/lib/py",
)
CACHE = Path(os.environ.get("KRUN_PY_CACHE", Path.home() / ".cache/krun/py"))
UA = "krun/2.1"

FILES = [
    "krun_common.py",
    "registry.py",
    "handlers/__init__.py",
    "handlers/install.py",
    "handlers/config.py",
    "handlers/ops.py",
    "handlers/system.py",
]

# Inlined at top of generated wrappers — curl | python3 has no local bootstrap module.
LOADER = """
import os, sys, urllib.request
from pathlib import Path

def _krun_bootstrap_path():
    base = os.environ.get("KRUN_PY_BASE", "https://raw.githubusercontent.com/kevin197011/krun/main/lib/py")
    cache = Path(os.environ.get("KRUN_PY_CACHE", Path.home() / ".cache/krun/py"))
    try:
        root = Path(__file__).resolve().parent
        if (root / "bootstrap.py").is_file():
            if str(root) not in sys.path:
                sys.path.insert(0, str(root))
            return
    except NameError:
        pass
    cache.mkdir(parents=True, exist_ok=True)
    dest = cache / "bootstrap.py"
    if not dest.is_file() or os.environ.get("KRUN_REFRESH"):
        req = urllib.request.Request(f"{base}/bootstrap.py", headers={"User-Agent": "krun/2.1"})
        dest.write_bytes(urllib.request.urlopen(req, timeout=120).read())
    if str(cache) not in sys.path:
        sys.path.insert(0, str(cache))

_krun_bootstrap_path()
""".strip()


def _fetch(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    dest.write_bytes(urllib.request.urlopen(req, timeout=120).read())


def setup() -> None:
    try:
        local = Path(__file__).resolve().parent
    except NameError:
        local = None

    if local and (local / "registry.py").is_file():
        root = str(local)
        if root not in sys.path:
            sys.path.insert(0, root)
        return

    CACHE.mkdir(parents=True, exist_ok=True)
    for rel in FILES:
        dest = CACHE / rel
        if dest.is_file() and not os.environ.get("KRUN_REFRESH"):
            continue
        url = f"{BASE}/{rel}"
        try:
            _fetch(url, dest)
        except OSError as exc:
            print(f"✗ bootstrap failed: {url} ({exc})")
            raise SystemExit(1) from exc
    root = str(CACHE)
    if root not in sys.path:
        sys.path.insert(0, root)
