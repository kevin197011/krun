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

FILES = [
    "krun_common.py",
    "registry.py",
    "handlers/__init__.py",
    "handlers/install.py",
    "handlers/config.py",
    "handlers/ops.py",
    "init_system.py",
]


def setup() -> None:
    local = Path(__file__).resolve().parent
    if (local / "registry.py").is_file():
        root = str(local)
        if root not in sys.path:
            sys.path.insert(0, root)
        return

    CACHE.mkdir(parents=True, exist_ok=True)
    for rel in FILES:
        dest = CACHE / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        if dest.is_file() and not os.environ.get("KRUN_REFRESH"):
            continue
        url = f"{BASE}/{rel}"
        try:
            urllib.request.urlretrieve(url, dest)
        except OSError as exc:
            print(f"✗ bootstrap failed: {url} ({exc})")
            raise SystemExit(1) from exc
    root = str(CACHE)
    if root not in sys.path:
        sys.path.insert(0, root)
