#!/usr/bin/env python3
# Copyright (c) 2026 kk
# MIT License
# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/scripts/install_lsyncd.py | sudo python3
# idempotent: safe to re-run
"""krun script: install_lsyncd"""

import gzip
import os, sys, time, random, urllib.error, urllib.request, importlib.util
from pathlib import Path
from urllib.parse import urlparse

_KRUN_UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 krun/2.1'

def _krun_browser_headers(url):
    parsed = urlparse(url)
    host = (parsed.netloc or "").lower()
    headers = {
        "User-Agent": _KRUN_UA,
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
        "Connection": "keep-alive",
        "Upgrade-Insecure-Requests": "1",
        "Sec-Fetch-Dest": "document",
        "Sec-Fetch-Mode": "navigate",
        "Sec-Fetch-Site": "none",
        "Sec-Fetch-User": "?1",
        "DNT": "1",
    }
    if "raw.githubusercontent.com" in host:
        headers["Accept"] = "application/vnd.github.raw+json, text/plain, */*;q=0.8"
        headers["Referer"] = "https://github.com/"
        headers["Sec-Fetch-Site"] = "cross-site"
        headers["Sec-Fetch-Dest"] = "empty"
        headers["Sec-Fetch-Mode"] = "cors"
    elif host.endswith("github.com") or host == "api.github.com":
        headers["Accept"] = "application/json, text/plain, */*;q=0.8"
        headers["Referer"] = "https://github.com/"
        headers["Sec-Fetch-Site"] = "same-origin" if host.endswith("github.com") else "cross-site"
        headers["Sec-Fetch-Dest"] = "empty"
        headers["Sec-Fetch-Mode"] = "cors"
    elif host:
        headers["Referer"] = f"{parsed.scheme or 'https'}://{host}/"
        headers["Sec-Fetch-Site"] = "same-origin"
    return headers

def _krun_retry_delay(attempt):
    time.sleep((2 ** attempt) + random.uniform(0.3, 1.5))

def _krun_refresh_wanted():
    return os.environ.get("KRUN_REFRESH", "0").strip().lower() in {"1", "true", "yes", "on"}

def _krun_mirror_urls(url):
    urls = []
    mirror = os.environ.get("KRUN_PY_MIRROR", "").strip()
    if mirror:
        urls.append(mirror.rstrip("/") + "/" + url)
    if "raw.githubusercontent.com" in url:
        urls.append(url.replace(
            "https://raw.githubusercontent.com/kevin197011/krun/main/",
            "https://cdn.jsdelivr.net/gh/kevin197011/krun@main/",
        ))
        urls.append("https://ghproxy.com/" + url)
    urls.append(url)
    seen, out = set(), []
    for item in urls:
        if item and item not in seen:
            seen.add(item)
            out.append(item)
    return out

def _krun_decompress(data):
    if len(data) >= 2 and data[:2] == b"\x1f\x8b":
        return gzip.decompress(data)
    return data

def _krun_read_text(path):
    data = path.read_bytes()
    return _krun_decompress(data).decode("utf-8").strip()

def _krun_fetch(url, timeout=60):
    errors = []
    retryable = {502, 503, 504}
    for target in _krun_mirror_urls(url):
        for attempt in range(2):
            try:
                req = urllib.request.Request(target, headers=_krun_browser_headers(target))
                return _krun_decompress(urllib.request.urlopen(req, timeout=timeout).read())
            except urllib.error.HTTPError as exc:
                if exc.code == 429:
                    errors.append(f"{target}: HTTP 429")
                    break
                if exc.code in retryable and attempt < 1:
                    _krun_retry_delay(attempt)
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
    stale = _krun_refresh_wanted()
    if not stale:
        try:
            remote_ver = _krun_decompress(_krun_fetch(f"{base}/krun/VERSION", timeout=30)).decode().strip()
        except OSError:
            remote_ver = ""
        ver_path = cache / "krun" / "VERSION"
        cached_ver = _krun_read_text(ver_path) if ver_path.is_file() else ""
        stale = bool(remote_ver and remote_ver != cached_ver)
    if not stale:
        required = ("krun/registry.py", "krun/handlers/config.py", "krun/handlers/system.py")
        stale = any(not (cache / rel).is_file() for rel in required)
    dest = cache / "krun" / "bootstrap.py"
    http_dest = cache / "krun" / "http.py"
    dest.parent.mkdir(parents=True, exist_ok=True)
    if not http_dest.is_file() or stale:
        try:
            http_dest.write_bytes(_krun_fetch(f"{base}/krun/http.py"))
        except OSError as exc:
            if not http_dest.is_file():
                print(f"✗ http client download failed: {exc}")
                raise SystemExit(1) from exc
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

SCRIPT = "install_lsyncd"

if __name__ == "__main__":
    _krun_run(SCRIPT)
