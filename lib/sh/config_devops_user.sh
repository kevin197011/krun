#!/usr/bin/env bash
# Copyright (c) 2026 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_devops_user.sh | bash
#
# Create devops user, passwordless sudo, SSH authorized_keys only.
# Rocky/RHEL (wheel) and Ubuntu/Debian (sudo). Requires root.

# vars
DEVOPS_USER="${DEVOPS_USER:-devops}"
DEVOPS_SSH_KEY="${DEVOPS_SSH_KEY:-ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCk5asJYrzYBdHGHR2i5ageIzuni7EYkdbxbqyqo9czuPWHUDbVyyP7sDos+3wr/WmOoylgjpjr8bsHNph1tze1E+rG1gXShEK4ERpG7pO0mTIST3HmElPl5wxNplNmwjSLGp7/FZ4ZOlXKt+xF9PEWe2/nSRNgXLaTCNfvy/8NXkjDpvEqdBfXVMr00imCoJ8Kf/juwX5Wt2bn48F3wIb63wz/2qHRQlV2r7UuZoE3Ph+2FICQHdMoJkZVKXj83JBOM+59HYJyW6XlxxQQVJge73UP2zNgGk2+x/k5p8oqdVAVjNCItKybCNdEljkj5p2KSk/JPSGyu8I96KciUdcJWhvP9JJCnLTmfm4zC55dCclctz9ME8Ml1k+ul2hlHwDstXRYwXcfpE/DmxQSMyYqStaNxl203aqnF/lZt4dZVURU9zXAcmltCNHCJQXYldYFnY0CaKV9AXJIuOCVyFGtzGumyRO3K3S0LN2MazkUCyFAVQq5KyHUXfK2V4Co7ECZNWfVlkCL2JndrwJ6Ek9aSGOpmaiTBZamBX7dwqbfWAWknYaPAYX7Lua91FXqi6EtQFkvnqfFPmqEt8yBIa1JCi/pLy5yNBXH+nieE+98LiUpn7Hj8+l8ke1JX8+8UF/SPz2oSNQ01ZzjJYKffSbJwlWUgaaxAOBqQWaH1xbm+Q== devops}"

# run code
krun::config::devops_user::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos / rocky / rhel
krun::config::devops_user::centos() {
    echo "Configuring devops user on Rocky/RHEL..."
    krun::config::devops_user::common wheel
}

# ubuntu / debian
krun::config::devops_user::debian() {
    echo "Configuring devops user on Ubuntu/Debian..."
    krun::config::devops_user::common sudo
}

# mac
krun::config::devops_user::mac() {
    echo "macOS not supported for config_devops_user.sh (use Rocky/Ubuntu)"
    return 1
}

# Create user, sudoers drop-in, authorized_keys. $1 = admin group (wheel|sudo).
krun::config::devops_user::common() {
    local admin_group="$1"
    local home_dir ssh_dir auth_keys key_blob sudoers_file

    [[ "$(id -u)" -ne 0 ]] && echo "✗ Run as root or with sudo" && return 1

    if ! getent group "$admin_group" >/dev/null 2>&1; then
        echo "✗ Admin group '${admin_group}' not found" >&2
        return 1
    fi

    if id "$DEVOPS_USER" &>/dev/null; then
        echo "✓ User '${DEVOPS_USER}' already exists"
        usermod -aG "$admin_group" "$DEVOPS_USER"
    else
        useradd -m -s /bin/bash -G "$admin_group" "$DEVOPS_USER"
        echo "✓ Created user '${DEVOPS_USER}' (group: ${admin_group})"
    fi

    home_dir="$(getent passwd "$DEVOPS_USER" | cut -d: -f6)"
    if [[ -z "$home_dir" || ! -d "$home_dir" ]]; then
        echo "✗ Home directory missing for ${DEVOPS_USER}" >&2
        return 1
    fi

    sudoers_file="/etc/sudoers.d/${DEVOPS_USER}"
    cat >"$sudoers_file" <<EOF
# Managed by krun config_devops_user.sh
${DEVOPS_USER} ALL=(ALL) NOPASSWD:ALL
EOF
    chmod 440 "$sudoers_file"
    if command -v visudo >/dev/null 2>&1; then
        visudo -cf "$sudoers_file" >/dev/null
    fi
    echo "✓ Passwordless sudo: ${sudoers_file}"

    key_blob="$(awk '{print $2}' <<<"$DEVOPS_SSH_KEY")"
    if [[ -z "$key_blob" ]]; then
        echo "✗ Invalid DEVOPS_SSH_KEY" >&2
        return 1
    fi

    ssh_dir="${home_dir}/.ssh"
    auth_keys="${ssh_dir}/authorized_keys"
    install -d -m 700 -o "$DEVOPS_USER" -g "$DEVOPS_USER" "$ssh_dir"
    touch "$auth_keys"
    chown "$DEVOPS_USER:$DEVOPS_USER" "$auth_keys"
    chmod 600 "$auth_keys"

    if grep -qF "$key_blob" "$auth_keys"; then
        echo "✓ SSH key already present: ${auth_keys}"
    else
        echo "$DEVOPS_SSH_KEY" >>"$auth_keys"
        echo "✓ Appended SSH key: ${auth_keys}"
    fi

    if command -v restorecon >/dev/null 2>&1; then
        restorecon -R "$ssh_dir" 2>/dev/null || true
    fi

    echo "✓ Done (user + sudo NOPASSWD + SSH key)"
}

# run main
krun::config::devops_user::run "$@"
