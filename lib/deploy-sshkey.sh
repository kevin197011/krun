#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# vars

# run code
krun::deploy::sshkey::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::deploy::sshkey::centos() {
    krun::deploy::sshkey::common
}

# debian code
krun::deploy::sshkey::debian() {
    krun::deploy::sshkey::common
}

# mac code
krun::deploy::sshkey::mac() {
    krun::deploy::sshkey::common
}

# common code
krun::deploy::sshkey::common() {
    key='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIeJ4XS+9S0yigZ04Ja6j5Y3gbdmd8FGwO9NwW+ibAf7xhWPNpkyC6sH+iucmkmefF5EVb1hKdEMXBEXl5GXUELzT8ccepZpoLxeaSE/qpy6/Ys6q4jWRoPdCfunZ87cY19lwA1e4zank1s7bxwhqa/2aO0Kd6VOgqf10XkQ1R3Cm0Qyycu3XqzJJ6jJDkHt37pHNbVRUG16xhY3faFpTVQuewJVCGdozOr+y+n+gcI3L7negfmVjLloyr+nXLrydWbDqtBir4wePpEoIjgcnRmdxHwBsfJg1hMfogJw6FzbozuB67rAQlvH+nkSNA1za7Atiyn/RUzdIUhtjjwcA0geXYRhG942sCGWda1MauzJlx8eYv8PUfdbnn0Df8aIFmlt6IDfc6wOe3avmBhEUNIfuEXq4ootH9Egrs4B2c0lhw6Aujqq1OXqtsVG7iF3Cp4FHLbeXsY1d5hzT02Znk3pT1PFf6KqL+THodAAlLca3wIZP0sCJhCDyFwvIPC50='
    grep -q "${key}" ~/.ssh/authorized_keys || echo "${key}" >>~/.ssh/authorized_keys
    echo "sshkey deploy done."
}

# run main
krun::deploy::sshkey::run "$@"
