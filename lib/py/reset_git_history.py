#!/usr/bin/env python3
# Copyright (c) 2025 kk
# MIT License
# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/reset_git_history.py | sudo python3
# idempotent: safe to re-run

import bootstrap
bootstrap.setup()
from registry import run_script

if __name__ == "__main__":
    run_script("reset_git_history")
