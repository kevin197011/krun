#!/usr/bin/env python3
"""Generate lib/py/scripts/*.py entrypoints from krun.registry.SCRIPTS."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SCRIPTS_DIR = ROOT / "scripts"
sys.path.insert(0, str(ROOT))

from krun.prefetch import INLINE  # noqa: E402
from krun.registry import SCRIPTS  # noqa: E402

# scripts/*.py = identity + curl header only; logic lives in krun/
TEMPLATE = '''#!/usr/bin/env python3
# Copyright (c) 2026 kk
# MIT License
# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/scripts/{name}.py | sudo python3
# idempotent: safe to re-run
"""krun script: {name}"""

{prefetch}

SCRIPT = "{name}"

if __name__ == "__main__":
    from krun.entry import main
    main(SCRIPT)
'''


def main() -> None:
    SCRIPTS_DIR.mkdir(exist_ok=True)
    for path in SCRIPTS_DIR.glob("*.py"):
        if path.name != "README.md":
            path.unlink()

    for name in sorted(SCRIPTS):
        out = SCRIPTS_DIR / f"{name}.py"
        out.write_text(TEMPLATE.format(name=name, prefetch=INLINE), encoding="utf-8")
        out.chmod(0o755)
        print(f"wrote scripts/{out.name}")

    print(f"total: {len(SCRIPTS)} scripts")


if __name__ == "__main__":
    main()
