#!/usr/bin/env python3
"""Stage-2 bootstrap: download/sync full krun package into cache."""

from __future__ import annotations

import os
import shutil
import sys
import time
import urllib.error
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
    "krun/handlers/jumpserver.py",
    "krun/handlers/system.py",
]


def _mirror_urls(url: str) -> list[str]:
    urls = [url]
    mirror = os.environ.get("KRUN_PY_MIRROR", "").strip()
    if mirror:
        urls.insert(0, f"{mirror.rstrip('/')}/{url}")
    if "raw.githubusercontent.com" in url:
        urls.append(f"https://ghproxy.com/{url}")
        urls.append(
            url.replace(
                "https://raw.githubusercontent.com/kevin197011/krun/main/",
                "https://cdn.jsdelivr.net/gh/kevin197011/krun@main/",
            )
        )
    seen: set[str] = set()
    out: list[str] = []
    for item in urls:
        if item and item not in seen:
            seen.add(item)
            out.append(item)
    return out


def fetch_bytes(url: str, *, timeout: int = 120) -> bytes:
    errors: list[str] = []
    for target in _mirror_urls(url):
        for attempt in range(4):
            try:
                req = urllib.request.Request(target, headers={"User-Agent": UA})
                return urllib.request.urlopen(req, timeout=timeout).read()
            except urllib.error.HTTPError as exc:
                if exc.code in (429, 502, 503, 504) and attempt < 3:
                    time.sleep(2 ** attempt)
                    continue
                errors.append(f"{target}: HTTP {exc.code}")
                break
            except OSError as exc:
                errors.append(f"{target}: {exc}")
                break
    raise OSError(f"fetch failed for {url}: " + "; ".join(errors))


def _fetch(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(fetch_bytes(url))


def _read_version(path: Path) -> str:
    if not path.is_file():
        return ""
    return path.read_text(encoding="utf-8").strip()


def _remote_version() -> str:
    try:
        return fetch_bytes(f"{BASE}/{VERSION_FILE}", timeout=30).decode().strip()
    except OSError:
        return ""


def _files_complete(root: Path) -> bool:
    return all((root / rel).is_file() for rel in FILES)


def _cache_stale() -> bool:
    if os.environ.get("KRUN_REFRESH"):
        return True
    if not _files_complete(CACHE):
        return True
    remote = _remote_version()
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
        for rel in FILES:
            dest = target / rel
            if dest.is_file() and not stale:
                continue
            _fetch(f"{BASE}/{rel}", dest)
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
