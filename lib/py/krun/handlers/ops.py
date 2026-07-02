"""Ops: disk cleanup, crane, deploy, media."""

from __future__ import annotations

import os
import subprocess
from pathlib import Path

from krun.common import has_cmd, platform, require_root, run

FREED = 0
STRESSED: list[str] = []


def _human(n: int) -> str:
    for unit, div in (("TiB", 1 << 40), ("GiB", 1 << 30), ("MiB", 1 << 20), ("KiB", 1 << 10)):
        if n >= div:
            return f"{n / div:.1f}{unit}"
    return f"{n}B"


def disk_cleanup() -> None:
    mode = os.environ.get("MODE", "auto")
    warn = int(os.environ.get("DISK_WARN_PERCENT", "80"))
    dry = os.environ.get("CLEAN_DRY_RUN", "0") == "1"

    def collect():
        global STRESSED
        STRESSED = []
        proc = subprocess.run(["df", "-P", "-h"], capture_output=True, text=True)
        for line in proc.stdout.splitlines()[1:]:
            parts = line.split()
            if len(parts) < 6:
                continue
            pct = int(parts[4].rstrip("%"))
            if pct >= warn:
                STRESSED.append(f"{parts[5]}:{pct}")

    def analyze():
        print("### disk overview")
        run(["df", "-h"])
        collect()
        print(f"### stressed (>={warn}%)")
        if not STRESSED:
            print(f"✓ no mount above {warn}%")
        for item in STRESSED:
            m, p = item.split(":")
            print(f"[WARN] {m} {p}%")

    def clean():
        nonlocal dry
        print("### safe cleanup")
        if dry:
            print(">>> DRY-RUN")
        journal_days = os.environ.get("CLEAN_JOURNAL_DAYS", "7")
        if has_cmd("journalctl") and not dry:
            run(["journalctl", f"--vacuum-time={journal_days}d"])
            print(f"✓ journal vacuum {journal_days}d")
        if platform() in {"rhel", "deb"}:
            require_root()
            if has_cmd("dnf"):
                run(["dnf", "clean", "all"])
            elif has_cmd("yum"):
                run(["yum", "clean", "all"])
            elif has_cmd("apt-get"):
                run(["apt-get", "clean"])
            print("✓ package cache cleaned")
        run(["df", "-h"])

    analyze()
    if mode == "analyze":
        return
    if mode == "clean" or (mode == "auto" and STRESSED):
        clean()
    elif mode == "auto":
        print(f"✓ usage OK (<{warn}%), skip cleanup")
    else:
        print(f"✗ invalid MODE={mode}")
        raise SystemExit(1)


def crane_copy() -> None:
    import sys
    src = os.environ.get("CRANE_COPY_SRC") or (sys.argv[1] if len(sys.argv) > 1 else "")
    dst = os.environ.get("CRANE_COPY_DST") or (sys.argv[2] if len(sys.argv) > 2 else "")
    if not src or not dst:
        print("usage: crane_copy.py <src> <dst>")
        raise SystemExit(1)
    if not has_cmd("crane"):
        print("✗ crane not found, run install_crane.py")
        raise SystemExit(1)
    run(["crane", "copy", src, dst])
    print(f"✓ copied {src} -> {dst}")


def deploy_node_exporter() -> None:
    require_root()
    compose = Path("/opt/node_exporter/docker-compose.yml")
    compose.parent.mkdir(parents=True, exist_ok=True)
    if not compose.is_file():
        compose.write_text(
            "services:\n  node_exporter:\n    image: prom/node-exporter:latest\n"
            "    ports:\n      - '9100:9100'\n    restart: unless-stopped\n",
            encoding="utf-8",
        )
    run(["docker", "compose", "-f", str(compose), "up", "-d"])
    print("✓ node_exporter deployed")


def delete_video() -> None:
    root = Path(os.environ.get("VIDEO_DIR", "/data/video"))
    if not root.is_dir():
        print(f"✗ not found: {root}")
        return
    exts = {".mp4", ".mkv", ".avi", ".mov"}
    count = 0
    for path in root.rglob("*"):
        if path.suffix.lower() in exts and path.is_file():
            if os.environ.get("DRY_RUN") == "1":
                print(path)
            else:
                path.unlink(missing_ok=True)
                count += 1
    print(f"✓ removed {count} video files")


def hello_world() -> None:
    print("hello world!...")
