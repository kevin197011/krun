#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config-ssh-authorized-keys.sh | bash
#
# 在目标主机上为 centos / devops 用户追加对应公钥，不覆盖已有 key。
# 需要 root 权限执行。

# vars
centos_ssh_key=${centos_ssh_key:-'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAx1HrAZccfxOdbStDtq0GEBfJwRGGdqrobQZapKns+y+gLuyaPVF31ex5xZ5yirPYH6ztp41fnW3cbFs9lseB/xQ7PpCz2s8lupcAF7V+sGjjuomTkkqLKsGOX+JwsyEWpqIKU/qYz81Ng3zgoFFrSPpIqYNIp12qXAzCcMolpz6IO3qvhgRcV1DD3cA8MKXN3SNugjD9n6Y+KL1xBrMbVzWuB7adA5mR4naR296z4oW3/mPk2i5LM11MfOXmDynFV9yCnmUC/IOFmBmKPssogSKDnoXmyPxAr24go82FJSdN6lkBYjuarJHk3oN1wOaKIiergO6FJR1UnTP/0vChWTm5AdVPPpYubgGRcnxCgGFBvmWthqGPdj5ykmkPlqv8na90vnaypXT16un9AR3kfZZbTaN3fMmcxrJG1xHn6clWGAiM6/7wAxVDPdWYCxVGbhrcxagsX6oYivtrDup3cDRnkfBQRlbOJB7asEv40mUesEsyfkhHTfT7wa0y3UinkaFgU9OP4ScXdVdn0a25pxyCAKo5ILOKAXlK2Mmmu1NdJrLbAtjo3kPO7DgYpVqv97mo1hZS3Giskjwfdv2QFSK5vKcqcJZPDDklciCHLrT0AwHsugw4mVSc7jLa27dUZ19PSpA80vrgf1uuHih0e+ozH4pWVR/NjqC4SNyX7FE= centos-common'}

devops_ssh_key=${devops_ssh_key:-'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEA0Gx8PyMgYM+ghk09FhUlxwlkhoGSoNdhbD5mG7n2G1ZjcIcQ+efY6rR+Vnhh1o1ndyQ2YXQD+iSOpybU/YRsUDlkz9HxzVm49pKDSzDGDPzvxnD146F5+SgL3Z9K6Qz6lo9HK2THgMqpdOtaKi465JjDRZhEhMBREYI1a6WpsWXcvzJVn4C8PbdnNGsyJORfMGRxVY6d5GDn6/59+L+rVueW8wrULpJT47kUc0YZjAGTYsRmaa7s5zzhmw59ufuZ8MK0tGgh8Y+Na5HGZB0s7nkNXzh1codRj14Eu0Z0RQt5/8oVf4WqRbVwlEO9FSQ8fTXP6oBbmMFVzn0WQqun58GVNOCM0lX9SMUI6znHmrb+8bVqAf9ZHEalEavmC4aTXlTLcMyfzPHaTLOAgUWg/RTK2XNZRTPNYk3r7y4VPnQl/mkI0VYE6/AL3sxg5LyIIF1YTDxLkBqySOM2W8BIz901ZlWfLr6SRt/25GiGr9B2WL9tm2Z/AgULtNrFT0BXBSwVUuZJiEmIyC/bCdZFe3ZLsoZULV98pLdomaoalU1fbf4cSCjvmZ9stH2p8nXKuarVZE1uRhGtVNDwwMlC/LcwNg8FJe0qbbGptnLc5mwzuPDNUhLHQw1I5ZXSF3xJmLwxznqCZkJUxP69okFd0EqATHE0Fu/OBJI66oaHWAU= devops-common'}

# run code
krun::config::ssh_authorized_keys::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::ssh_authorized_keys::centos() {
    echo "配置 SSH authorized_keys（CentOS/RHEL）..."
    krun::config::ssh_authorized_keys::common
}

# debian code
krun::config::ssh_authorized_keys::debian() {
    echo "配置 SSH authorized_keys（Debian/Ubuntu）..."
    krun::config::ssh_authorized_keys::common
}

# mac code
krun::config::ssh_authorized_keys::mac() {
    echo "配置 SSH authorized_keys（macOS）..."
    krun::config::ssh_authorized_keys::common
}

# 为指定用户追加公钥；已存在则跳过，不覆盖 authorized_keys 中其他 key。
krun::config::ssh_authorized_keys::append_key_for_user() {
    local target_user="$1"
    local new_key="$2"
    local home_dir key_blob ssh_dir auth_keys

    if ! id "$target_user" &>/dev/null; then
        echo "[${target_user}] 用户不存在，跳过"
        return 0
    fi

    home_dir="$(awk -F: -v u="$target_user" '$1==u {print $6; exit}' /etc/passwd)"
    if [[ -z "$home_dir" ]]; then
        echo "[${target_user}] 无法解析家目录，跳过" >&2
        return 0
    fi

    key_blob="$(awk '{print $2}' <<<"$new_key")"
    if [[ -z "$key_blob" ]]; then
        echo "[${target_user}] 公钥格式无效" >&2
        return 1
    fi

    ssh_dir="${home_dir}/.ssh"
    auth_keys="${ssh_dir}/authorized_keys"

    install -d -m 700 -o "$target_user" -g "$target_user" "$ssh_dir"
    touch "$auth_keys"
    chown "$target_user:$target_user" "$auth_keys"
    chmod 600 "$auth_keys"

    if grep -qF "$key_blob" "$auth_keys"; then
        echo "[${target_user}] 已存在，跳过: ${auth_keys}"
        return 0
    fi

    echo "$new_key" >>"$auth_keys"
    echo "[${target_user}] 已追加: ${auth_keys}"
}

krun::config::ssh_authorized_keys::common() {
    [[ "$(id -u)" -ne 0 ]] && echo "✗ 请使用 root 或 sudo 执行" && return 1

    krun::config::ssh_authorized_keys::append_key_for_user centos "$centos_ssh_key"
    krun::config::ssh_authorized_keys::append_key_for_user devops "$devops_ssh_key"

    echo "✓ SSH authorized_keys 配置完成"
}

# run main
krun::config::ssh_authorized_keys::run "$@"
