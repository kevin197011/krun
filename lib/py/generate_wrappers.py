#!/usr/bin/env python3
"""Generate lib/py/*.py entrypoints from registry.SCRIPTS."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))

from bootstrap import LOADER  # noqa: E402
from registry import SCRIPTS  # noqa: E402

TEMPLATE = '''#!/usr/bin/env python3
# Copyright (c) 2025 kk
# MIT License
# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/{name}.py | sudo python3
# idempotent: safe to re-run

{loader}

import bootstrap
bootstrap.setup()
from registry import run_script

if __name__ == "__main__":
    run_script("{name}")
'''


def main() -> None:
    keep = {"bootstrap.py", "krun_common.py", "registry.py", "generate_wrappers.py"}
    for path in ROOT.glob("*.py"):
        if path.name not in keep:
            path.unlink()

    (ROOT / "handlers").mkdir(exist_ok=True)

    for name in sorted(SCRIPTS):
        out = ROOT / f"{name}.py"
        out.write_text(TEMPLATE.format(name=name, loader=LOADER), encoding="utf-8")
        out.chmod(0o755)
        print(f"wrote {out.name}")

    print(f"total: {len(SCRIPTS)} scripts")


if __name__ == "__main__":
    main()
