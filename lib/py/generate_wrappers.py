#!/usr/bin/env python3
"""Generate lib/py/scripts/*.py entrypoints from krun.registry.SCRIPTS."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SCRIPTS = ROOT / "scripts"
sys.path.insert(0, str(ROOT))

from krun.bootstrap import LOADER  # noqa: E402
from krun.registry import SCRIPTS as SCRIPT_NAMES  # noqa: E402

TEMPLATE = '''#!/usr/bin/env python3
# Copyright (c) 2026 kk
# MIT License
# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/scripts/{name}.py | sudo python3
# idempotent: safe to re-run

{loader}

from krun import bootstrap
bootstrap.setup()
from krun.registry import run_script

if __name__ == "__main__":
    run_script("{name}")
'''


def main() -> None:
    SCRIPTS.mkdir(exist_ok=True)
    for path in SCRIPTS.glob("*.py"):
        path.unlink()

    for name in sorted(SCRIPT_NAMES):
        out = SCRIPTS / f"{name}.py"
        out.write_text(TEMPLATE.format(name=name, loader=LOADER), encoding="utf-8")
        out.chmod(0o755)
        print(f"wrote scripts/{out.name}")

    print(f"total: {len(SCRIPT_NAMES)} scripts")


if __name__ == "__main__":
    main()
