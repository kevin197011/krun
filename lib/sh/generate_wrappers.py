#!/usr/bin/env python3
"""Generate lib/sh/*.sh thin wrappers that delegate to lib/py/scripts/*.py.

Naming: same stem as Python (`init_system.sh` ↔ `init_system.py`).

Native (hand-maintained) scripts are preserved:
  - install_python3.sh
  - install_node_exporter_offline.sh
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]  # lib/
PY_ROOT = ROOT / "py"
SH_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(PY_ROOT))

from krun.registry import SCRIPTS  # noqa: E402

NATIVE = {
    "install_python3.sh",
    "install_node_exporter_offline.sh",
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
    echo "python3 not found; bootstrapping via install_python3.sh..."
    curl -fsSL "{raw_sh}/install_python3.sh" | bash
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


def main() -> None:
    SH_DIR.mkdir(parents=True, exist_ok=True)

    wanted: dict[str, str] = {f"{name}.sh": name for name in SCRIPTS}
    keep = set(NATIVE) | set(wanted)

    for path in SH_DIR.glob("*.sh"):
        if path.name not in keep:
            path.unlink()
            print(f"removed stale {path.name}")

    for fname, py_name in sorted(wanted.items()):
        out = SH_DIR / fname
        out.write_text(
            TEMPLATE.format(
                sh_name=fname,
                py_name=py_name,
                raw_py=RAW_PY,
                raw_sh=RAW_SH,
            ),
            encoding="utf-8",
        )
        out.chmod(0o755)
        print(f"wrote {fname} -> {py_name}.py")

    print(f"total wrappers: {len(wanted)}; native kept: {', '.join(sorted(NATIVE))}")


if __name__ == "__main__":
    main()
