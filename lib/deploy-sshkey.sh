#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/deploy-sshkey.sh | bash

# vars

# run code
krun::deploy::sshkey::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
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
    key_opslab='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSWj/bmwFbJtgbrKjP3HXH9UIKT3Z4rV8lK6KDRPxeeCh09Vec8KEEVSEzze3YJnkurINxlOnI3xuuYKKuucpVbkOvcbykBI0FBtETmszfwy67qo9Sd/j1VHz062G5rtSRI0GepWJ7K+cTFOTwXTNdrHrIMUGwo7XVIZZrQTzOBXDYNMgk8/KsvX1k0sYFtcOOBsJzR9WWuSXasvsATVOh7IadV4E8oXFsWD59PXW2XpIAhdT570fjKq8kPTmhppVPgxPq5xE9A4QyHKhe9R3wNtrJ9Zo2IXT9zA2tMlTOYwGBFn3/V60BXXlFmujbbcZJI2ye3xFCVr8Wl7a/oxNhCffh6+VJaXvgb5XvYZzSx0nENhDig4DdvX2j6OoOrSEpJLwPKtqS35mZCzyhkZv1WcD2wewnJCic4vcHlwpX04k37FQB0NG0jXjkeML/hx6lFVNGhGPFjGunwh2T215hktu7APrw+G8JElVJbf6hU8ir2Cc5LPDprq2Id0sKNXs= root@ops-lab'
    grep -q "${key}" ~/.ssh/authorized_keys || echo "${key}" >>~/.ssh/authorized_keys
    grep -q "${key_opslab}" ~/.ssh/authorized_keys || echo "${key_opslab}" >>~/.ssh/authorized_keys
    echo "sshkey deploy done."
}

# run main
krun::deploy::sshkey::run "$@"
