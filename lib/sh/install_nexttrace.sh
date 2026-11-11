#!/usr/bin/env bash
# Copyright (c) 2026 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_nexttrace.sh | bash

# vars
# flavor: full (default) | tiny | ntr — see https://github.com/nxtrace/NTrace-core
nexttrace_flavor=${nexttrace_flavor:-full}

# run code
krun::install::nexttrace::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::nexttrace::centos() {
    krun::install::nexttrace::common
}

# debian code
krun::install::nexttrace::debian() {
    krun::install::nexttrace::common
}

# mac code
krun::install::nexttrace::mac() {
    if command -v nexttrace >/dev/null 2>&1; then
        echo "✓ nexttrace already installed"
        nexttrace --version || true
        return
    fi
    if command -v brew >/dev/null 2>&1; then
        brew install nexttrace
        echo "✓ nexttrace installed via Homebrew"
        nexttrace --version || true
        return
    fi
    krun::install::nexttrace::common
}

# common code
krun::install::nexttrace::common() {
    if command -v nexttrace >/dev/null 2>&1; then
        echo "✓ nexttrace already installed"
        nexttrace --version || true
        return
    fi

    command -v curl >/dev/null 2>&1 || { echo "✗ curl required"; exit 1; }

    echo "Installing NextTrace (flavor=${nexttrace_flavor})..."
    # Official one-key installer: https://github.com/nxtrace/NTrace-core
    if [[ "$nexttrace_flavor" == "full" ]]; then
        curl -fsSL https://nxtrace.org/nt | bash
    else
        curl -fsSL https://nxtrace.org/nt | bash -s -- --flavor "$nexttrace_flavor"
    fi

    if command -v nexttrace >/dev/null 2>&1; then
        echo "✓ nexttrace installed"
        nexttrace --version || true
    elif command -v nexttrace-tiny >/dev/null 2>&1; then
        echo "✓ nexttrace-tiny installed"
        nexttrace-tiny --version || true
    elif command -v ntr >/dev/null 2>&1; then
        echo "✓ ntr installed"
        ntr --version || true
    else
        echo "✗ nexttrace command not found after install"
        exit 1
    fi
}

# run main
krun::install::nexttrace::run "$@"
