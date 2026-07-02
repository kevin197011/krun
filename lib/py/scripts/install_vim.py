#!/usr/bin/env python3
# Copyright (c) 2026 kk
# MIT License
# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/scripts/install_vim.py | sudo python3
# idempotent: safe to re-run

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

from krun import bootstrap
bootstrap.setup()
from krun.registry import run_script

if __name__ == "__main__":
    run_script("install_vim")
