#!/usr/bin/env python3
"""Stage-2/3 entry: bootstrap cache then dispatch to registry handler."""

from __future__ import annotations


def main(script: str) -> None:
    from krun.bootstrap import setup
    from krun.registry import run_script

    setup()
    run_script(script)
