#!/usr/bin/env python3
"""Stage-2 bootstrap: download/sync full krun package into cache."""

from __future__ import annotations

import importlib.util
import os
import shutil
import sys
from pathlib import Path

BASE = os.environ.get(
    "KRUN_PY_BASE",
    "https://raw.githubusercontent.com/kevin197011/krun/main/lib/py",
)
CACHE = Path(os.environ.get("KRUN_PY_CACHE", Path.home() / ".cache/krun/py"))
VERSION_FILE = "krun/VERSION"
HTTP_FILE = "krun/http.py"

FILES = [
    HTTP_FILE,
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
    "krun/handlers/jumpserver.py",
    "krun/handlers/system.py",
]


def refresh_wanted() -> bool:
    """Default on; set KRUN_REFRESH=0 to use cache when version matches."""
    return os.environ.get("KRUN_REFRESH", "1").strip().lower() not in {"0", "false", "no", "off"}


def _load_http_fetch():
    """Load fetch_bytes from sibling http.py (cache may not have krun package yet)."""
    try:
        from krun.http import fetch_bytes

        return fetch_bytes
    except ImportError:
        pass
    path = Path(__file__).resolve().parent / "http.py"
    if not path.is_file():
        return None
    spec = importlib.util.spec_from_file_location("krun.http", path)
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)
    return mod.fetch_bytes


def _bootstrap_fetch(url: str, *, timeout: int = 120) -> bytes:
    """Fetch before krun/http.py is importable from cache."""
    fn = _load_http_fetch()
    if fn is not None:
        return fn(url, timeout=timeout)
    try:
        from krun.http import fetch_bytes

        return fetch_bytes(url, timeout=timeout)
    except ImportError as exc:
        raise OSError("krun/http.py missing from cache; re-run prefetch") from exc


def _fetch(url: str, dest: Path, fetch) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(fetch(url))


def _read_version(path: Path) -> str:
    if not path.is_file():
        return ""
    try:
        from krun.http import decode_text

        return decode_text(path.read_bytes())
    except Exception:
        return path.read_text(encoding="utf-8", errors="replace").strip()


def _remote_version(fetch) -> str:
    try:
        from krun.http import decode_text

        return decode_text(fetch(f"{BASE}/{VERSION_FILE}", timeout=30))
    except OSError:
        return ""


def _files_complete(root: Path) -> bool:
    return all((root / rel).is_file() for rel in FILES)


def _cache_stale() -> bool:
    if refresh_wanted():
        return True
    if not _files_complete(CACHE):
        return True
    fetch = _load_http_fetch() or _bootstrap_fetch
    remote = _remote_version(fetch)
    if not remote:
        return False
    return remote != _read_version(CACHE / VERSION_FILE)


def _clear_krun_modules() -> None:
    for key in list(sys.modules):
        if key == "krun" or key.startswith("krun."):
            del sys.modules[key]


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
    staging = CACHE / ".staging"
    target = staging if stale else CACHE

    if stale:
        if staging.is_dir():
            shutil.rmtree(staging, ignore_errors=True)
        staging.mkdir(parents=True, exist_ok=True)

    try:
        http_dest = target / HTTP_FILE
        if stale or not http_dest.is_file():
            _fetch(f"{BASE}/{HTTP_FILE}", http_dest, _bootstrap_fetch)

        fetch = _load_http_fetch()
        if fetch is None:
            fetch = _bootstrap_fetch

        for rel in FILES:
            if rel == HTTP_FILE and http_dest.is_file() and not stale:
                continue
            dest = target / rel
            if dest.is_file() and not stale:
                continue
            _fetch(f"{BASE}/{rel}", dest, fetch)
    except OSError as exc:
        if stale and staging.is_dir():
            shutil.rmtree(staging, ignore_errors=True)
        if _files_complete(CACHE):
            print(f"⚠ refresh failed, using cached krun ({exc})")
        else:
            print(f"✗ bootstrap failed: {exc}")
            raise SystemExit(1) from exc
        stale = False
    else:
        if stale:
            if (CACHE / "krun").is_dir():
                shutil.rmtree(CACHE / "krun", ignore_errors=True)
            shutil.move(str(staging / "krun"), str(CACHE / "krun"))
            shutil.rmtree(staging, ignore_errors=True)
            _clear_krun_modules()

    path = str(CACHE)
    if path not in sys.path:
        sys.path.insert(0, path)
