#!/usr/bin/env python3
# Copyright (c) 2026 kk
# MIT License
# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/scripts/install_ruby.py | sudo python3
# idempotent: safe to re-run
"""krun script: install_ruby"""

import os, sys, time, urllib.error, urllib.request, importlib.util
from pathlib import Path

def _krun_refresh_wanted():
    return os.environ.get("KRUN_REFRESH", "1").strip().lower() not in {"0", "false", "no", "off"}

def _krun_mirror_urls(url):
    urls = [url]
    mirror = os.environ.get("KRUN_PY_MIRROR", "").strip()
    if mirror:
        urls.insert(0, mirror.rstrip("/") + "/" + url)
    if "raw.githubusercontent.com" in url:
        urls.append("https://ghproxy.com/" + url)
        urls.append(url.replace(
            "https://raw.githubusercontent.com/kevin197011/krun/main/",
            "https://cdn.jsdelivr.net/gh/kevin197011/krun@main/",
        ))
    seen, out = set(), []
    for item in urls:
        if item and item not in seen:
            seen.add(item)
            out.append(item)
    return out

def _krun_fetch(url, timeout=120):
    errors = []
    for target in _krun_mirror_urls(url):
        for attempt in range(4):
            try:
                req = urllib.request.Request(target, headers={"User-Agent": "krun/2.1"})
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
    raise OSError("fetch failed for " + url + ": " + "; ".join(errors))

def _krun_prefetch():
    base = os.environ.get("KRUN_PY_BASE", "https://raw.githubusercontent.com/kevin197011/krun/main/lib/py")
    cache = Path(os.environ.get("KRUN_PY_CACHE", Path.home() / ".cache/krun/py"))
    try:
        here = Path(__file__).resolve().parent
        for root in (here.parent, here):
            if (root / "krun" / "bootstrap.py").is_file():
                if str(root) not in sys.path:
                    sys.path.insert(0, str(root))
                return cache
    except NameError:
        pass
    cache.mkdir(parents=True, exist_ok=True)
    try:
        remote_ver = _krun_fetch(f"{base}/krun/VERSION", timeout=30).decode().strip()
    except OSError:
        remote_ver = ""
    ver_path = cache / "krun" / "VERSION"
    cached_ver = ver_path.read_text(encoding="utf-8").strip() if ver_path.is_file() else ""
    stale = _krun_refresh_wanted() or (remote_ver and remote_ver != cached_ver)
    if not stale:
        required = ("krun/registry.py", "krun/handlers/config.py", "krun/handlers/system.py")
        stale = any(not (cache / rel).is_file() for rel in required)
    dest = cache / "krun" / "bootstrap.py"
    dest.parent.mkdir(parents=True, exist_ok=True)
    if not dest.is_file() or stale:
        try:
            dest.write_bytes(_krun_fetch(f"{base}/krun/bootstrap.py"))
        except OSError as exc:
            if dest.is_file():
                print(f"⚠ bootstrap refresh failed, using cache ({exc})")
            else:
                print(f"✗ bootstrap download failed: {exc}")
                raise SystemExit(1) from exc
        else:
            if stale:
                for rel in ("krun/registry.py", "krun/handlers/config.py", "krun/handlers/system.py"):
                    (cache / rel).unlink(missing_ok=True)
    if str(cache) not in sys.path:
        sys.path.insert(0, str(cache))
    return cache

def _krun_run(script):
    cache = _krun_prefetch()
    boot = cache / "krun" / "bootstrap.py"
    spec = importlib.util.spec_from_file_location("krun_bootstrap", boot)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    mod.setup()
    from krun.registry import run_script
    run_script(script)

SCRIPT = "install_ruby"

if __name__ == "__main__":
    _krun_run(SCRIPT)
