#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/crane-copy.sh | bash

# vars
# 两端仓库认证：crane 使用 ~/.docker/config.json，需对源、目标仓库分别登录
#   docker login ghcr.io
#   docker login harbor.slileisure.com
# 或设置 DOCKER_CONFIG 指向含 auth 的 config.json
#
# 直接执行: krun crane-copy.sh <源镜像> <目标镜像>
# 或环境变量: CRANE_COPY_SRC / CRANE_COPY_DST

krun::crane::copy::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos / debian / mac 共用
krun::crane::copy::centos() { krun::crane::copy::common; }
krun::crane::copy::debian() { krun::crane::copy::common; }
krun::crane::copy::mac()   { krun::crane::copy::common; }

krun::crane::copy::common() {
    command -v crane >/dev/null 2>&1 || { echo "crane not found. run: krun install-crane.sh"; exit 1; }

    local src="${CRANE_COPY_SRC:-${1:-}}"
    local dst="${CRANE_COPY_DST:-${2:-}}"

    if [[ -z "$src" || -z "$dst" ]]; then
        echo "Usage: krun crane-copy.sh <源镜像> <目标镜像>"
        echo "   or: CRANE_COPY_SRC=<src> CRANE_COPY_DST=<dst> krun crane-copy.sh"
        echo "Example: krun crane-copy.sh ghcr.io/kevin197011/doris-webhook:main-aaef595 harbor.slileisure.com/devops/doris-webhook:main-aaef595"
        exit 1
    fi

    echo "Copy: $src -> $dst"
    crane copy "$src" "$dst"
    echo "✓ Done"
}

# run main
krun::crane::copy::run "$@"
