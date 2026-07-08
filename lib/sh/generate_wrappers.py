#!/usr/bin/env python3
"""Generate lib/sh/*.sh thin wrappers that delegate to lib/py/scripts/*.py.

Native (hand-maintained) scripts are preserved:
  - install-python3.sh
  - install-node-exporter-offline.sh

All other wrappers always call the Python implementation so logic stays in sync.
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]  # lib/
PY_ROOT = ROOT / "py"
SH_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(PY_ROOT))

from krun.registry import SCRIPTS  # noqa: E402

# Keep historical curl URLs stable (kebab / mixed underscore names).
# py SCRIPT name -> sh filename
NAME_MAP: dict[str, str] = {
    "disk_cleanup": "analyze-disk-cleanup.sh",
    "install_fonts_nerd_jetbrains": "install-fonts-nerd-JetBrainsMono.sh",
    "install_node_exporter": "install-node_exporter.sh",
    "install_blackbox_exporter": "install-blackbox_exporter.sh",
    "deploy_node_exporter": "deploy-node_exporter.sh",
    "install_oh_my_zsh": "install-oh_my_zsh.sh",
    "install_percona_toolkit": "install-percona_toolkit.sh",
    "install_puppet_bolt": "install-puppet_bolt.sh",
    "update_vagrant_box": "update-vagrant_box.sh",
}

NATIVE = {
    "install-python3.sh",
    "install-node-exporter-offline.sh",
}

RAW_PY = "https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/scripts"
RAW_SH = "https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh"

TEMPLATE = """\
#!/usr/bin/env bash
# Copyright (c) 2026 kk
# MIT License
#
# GENERATED — do not edit by hand. Run: rake lib:sh:generate
# Logic lives in lib/py (this wrapper only delegates).
#
# curl exec:
# curl -fsSL {raw_sh}/{sh_name} | sudo bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_PY="{py_name}"
RAW_PY="{raw_py}/${{SCRIPT_PY}}.py"

krun::sh::ensure_python3() {{
    if command -v python3 >/dev/null 2>&1; then
        return 0
    fi
    echo "python3 not found; bootstrapping via install-python3.sh..."
    curl -fsSL "{raw_sh}/install-python3.sh" | bash
    command -v python3 >/dev/null 2>&1 || {{
        echo "✗ python3 still missing after bootstrap"
        exit 1
    }}
}}

krun::sh::run() {{
    krun::sh::ensure_python3
    # Prefer local checkout when present (dev / installed tree).
    local here
    here="$(cd "$(dirname "${{BASH_SOURCE[0]:-$0}}")" && pwd)" 2>/dev/null || here=""
    if [[ -n "$here" && -f "$here/../py/scripts/${{SCRIPT_PY}}.py" ]]; then
        exec python3 "$here/../py/scripts/${{SCRIPT_PY}}.py" "$@"
    fi
    if [[ -n "$here" && -f "$here/../../lib/py/scripts/${{SCRIPT_PY}}.py" ]]; then
        exec python3 "$here/../../lib/py/scripts/${{SCRIPT_PY}}.py" "$@"
    fi
    curl -fsSL "$RAW_PY" | exec python3 - "$@"
}}

krun::sh::run "$@"
"""


def sh_name_for(py_name: str) -> str:
    if py_name in NAME_MAP:
        return NAME_MAP[py_name]
    return py_name.replace("_", "-") + ".sh"


def main() -> None:
    SH_DIR.mkdir(parents=True, exist_ok=True)

    keep = set(NATIVE)
    wanted: dict[str, str] = {}
    for py_name in sorted(SCRIPTS):
        fname = sh_name_for(py_name)
        wanted[fname] = py_name
        keep.add(fname)

    # Remove stale generated wrappers (never touch native).
    for path in SH_DIR.glob("*.sh"):
        if path.name in NATIVE:
            continue
        if path.name not in wanted:
            path.unlink()
            print(f"removed stale {path.name}")

    for fname, py_name in sorted(wanted.items()):
        out = SH_DIR / fname
        content = TEMPLATE.format(
            sh_name=fname,
            py_name=py_name,
            raw_py=RAW_PY,
            raw_sh=RAW_SH,
        )
        out.write_text(content, encoding="utf-8")
        out.chmod(0o755)
        print(f"wrote {fname} -> {py_name}.py")

    print(f"total wrappers: {len(wanted)}; native kept: {', '.join(sorted(NATIVE))}")


if __name__ == "__main__":
    main()
