#!/usr/bin/env bash
# Copyright (c) 2026 kk
# MIT License
#
# GENERATED — do not edit by hand. Run: rake lib:sh:generate
# Logic lives in lib/py (this wrapper only delegates).
#
# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install-oh_my_zsh.sh | sudo bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_PY="install_oh_my_zsh"
RAW_PY="https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/scripts/${SCRIPT_PY}.py"

krun::sh::ensure_python3() {
    if command -v python3 >/dev/null 2>&1; then
        return 0
    fi
    echo "python3 not found; bootstrapping via install-python3.sh..."
    curl -fsSL "https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install-python3.sh" | bash
    command -v python3 >/dev/null 2>&1 || {
        echo "✗ python3 still missing after bootstrap"
        exit 1
    }
}

krun::sh::run() {
    krun::sh::ensure_python3
    # Prefer local checkout when present (dev / installed tree).
    local here
    here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)" 2>/dev/null || here=""
    if [[ -n "$here" && -f "$here/../py/scripts/${SCRIPT_PY}.py" ]]; then
        exec python3 "$here/../py/scripts/${SCRIPT_PY}.py" "$@"
    fi
    if [[ -n "$here" && -f "$here/../../lib/py/scripts/${SCRIPT_PY}.py" ]]; then
        exec python3 "$here/../../lib/py/scripts/${SCRIPT_PY}.py" "$@"
    fi
    curl -fsSL "$RAW_PY" | exec python3 - "$@"
}

krun::sh::run "$@"
