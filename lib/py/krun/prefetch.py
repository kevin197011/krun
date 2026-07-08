#!/usr/bin/env python3
"""Stage-1 bootstrap: put krun on sys.path before any krun import (curl | python3)."""

from __future__ import annotations

import importlib.util
import os
import shutil
import sys
from pathlib import Path

from krun.http import decode_text, fetch_bytes, inline_bootstrap

BASE = os.environ.get(
    "KRUN_PY_BASE",
    "https://raw.githubusercontent.com/kevin197011/krun/main/lib/py",
)
CACHE = Path(os.environ.get("KRUN_PY_CACHE", Path.home() / ".cache/krun/py"))
_REQUIRED = (
    "krun/registry.py",
    "krun/handlers/config.py",
    "krun/handlers/system.py",
)

INLINE = inline_bootstrap()


def refresh_wanted() -> bool:
    return os.environ.get("KRUN_REFRESH", "0").strip().lower() in {"1", "true", "yes", "on"}


def _fetch_version(base: str) -> str:
    try:
        return decode_text(fetch_bytes(f"{base}/krun/VERSION", timeout=30))
    except OSError:
        return ""


def _cache_incomplete(cache: Path) -> bool:
    return any(not (cache / rel).is_file() for rel in _REQUIRED)


def prefetch_path() -> None:
    """Download bootstrap.py and add cache root to sys.path."""
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
    stale = refresh_wanted()
    if not stale:
        remote_ver = _fetch_version(base)
        ver_path = cache / "krun" / "VERSION"
        if ver_path.is_file():
            try:
                cached_ver = decode_text(ver_path.read_bytes())
            except OSError:
                cached_ver = ""
        else:
            cached_ver = ""
        stale = bool(remote_ver and remote_ver != cached_ver)
    if not stale:
        stale = _cache_incomplete(cache)

    dest = cache / "krun" / "bootstrap.py"
    http_dest = cache / "krun" / "http.py"
    dest.parent.mkdir(parents=True, exist_ok=True)
    if not http_dest.is_file() or stale:
        try:
            http_dest.write_bytes(fetch_bytes(f"{base}/krun/http.py"))
        except OSError as exc:
            if not http_dest.is_file():
                print(f"✗ http client download failed: {exc}")
                raise SystemExit(1) from exc
    if not dest.is_file() or stale:
        try:
            dest.write_bytes(fetch_bytes(f"{base}/krun/bootstrap.py"))
        except OSError as exc:
            if dest.is_file():
                print(f"⚠ bootstrap refresh failed, using cache ({exc})")
            else:
                print(f"✗ bootstrap download failed: {exc}")
                raise SystemExit(1) from exc
        else:
            if stale:
                for rel in _REQUIRED:
                    (cache / rel).unlink(missing_ok=True)

    path = str(cache)
    if path not in sys.path:
        sys.path.insert(0, path)


def _load_bootstrap():
    boot = CACHE / "krun" / "bootstrap.py"
    if not boot.is_file():
        print(f"✗ bootstrap missing: {boot}")
        raise SystemExit(1)
    spec = importlib.util.spec_from_file_location("krun_bootstrap", boot)
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)
    return mod


def run(script: str) -> None:
    """Prefetch bootstrap, sync cache, dispatch script (safe for curl | python3)."""
    prefetch_path()
    try:
        root = Path(__file__).resolve().parent.parent
        if (root / "krun" / "registry.py").is_file():
            from krun.bootstrap import setup
            from krun.registry import run_script

            setup()
            run_script(script)
            return
    except NameError:
        pass
    _load_bootstrap().setup()
    from krun.registry import run_script

    run_script(script)
