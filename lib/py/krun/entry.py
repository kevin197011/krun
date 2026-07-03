#!/usr/bin/env python3
"""Stage-3 entry when krun is fully available (local dev). curl scripts call bootstrap.setup() directly."""

from __future__ import annotations


def main(script: str) -> None:
    from krun.bootstrap import setup
    from krun.registry import run_script

    setup()
    run_script(script)
