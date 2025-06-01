#!/usr/bin/env bash

# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-ssh.sh | bash

# vars

# run code
krun::config::ssh::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::ssh::centos() {
    echo "Configuring SSH on CentOS/RHEL..."

    # Install OpenSSH server if not already installed
    yum install -y openssh-server openssh-clients

    # Enable and start SSH service
    systemctl enable sshd
    systemctl start sshd || true

    krun::config::ssh::common
}

# debian code
krun::config::ssh::debian() {
    echo "Configuring SSH on Debian/Ubuntu..."

    # Install OpenSSH server if not already installed
    apt-get update
    apt-get install -y openssh-server openssh-client

    # Enable and start SSH service
    systemctl enable ssh
    systemctl start ssh || true

    krun::config::ssh::common
}

# mac code
krun::config::ssh::mac() {
    echo "Configuring SSH on macOS..."

    # macOS comes with SSH by default, just configure it
    # Enable Remote Login (SSH) if not already enabled
    sudo systemsetup -setremotelogin on 2>/dev/null || echo "Remote login configuration may require manual setup"

    krun::config::ssh::common
}

# common code
krun::config::ssh::common() {
    echo "Applying SSH security configurations..."

    # Backup original sshd_config
    if [[ -f /etc/ssh/sshd_config ]] && [[ ! -f /etc/ssh/sshd_config.bak ]]; then
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
        echo "✓ Backed up original sshd_config"
    fi

    # Apply security configurations
    local sshd_config="/etc/ssh/sshd_config"

    if [[ -f "$sshd_config" ]]; then
        # Disable password authentication (use key-based auth only)
        perl -i -pe 's/(\s*)(#*)(\s*)PasswordAuthentication(.*)/PasswordAuthentication no/g' "$sshd_config"

        # Disable root login
        perl -i -pe 's/(\s*)(#*)(\s*)PermitRootLogin(.*)/PermitRootLogin no/g' "$sshd_config"

        # Additional security settings
        grep -q "^Protocol 2" "$sshd_config" || echo "Protocol 2" >>"$sshd_config"
        grep -q "^MaxAuthTries" "$sshd_config" || echo "MaxAuthTries 3" >>"$sshd_config"
        grep -q "^ClientAliveInterval" "$sshd_config" || echo "ClientAliveInterval 600" >>"$sshd_config"
        grep -q "^ClientAliveCountMax" "$sshd_config" || echo "ClientAliveCountMax 0" >>"$sshd_config"
        grep -q "^X11Forwarding" "$sshd_config" || echo "X11Forwarding no" >>"$sshd_config"
        grep -q "^UseDNS" "$sshd_config" || echo "UseDNS no" >>"$sshd_config"

        # Disable empty passwords
        perl -i -pe 's/(\s*)(#*)(\s*)PermitEmptyPasswords(.*)/PermitEmptyPasswords no/g' "$sshd_config"

        echo "✓ Applied SSH security configurations"
    else
        echo "⚠ SSH config file not found at $sshd_config"
    fi

    # Restart SSH service
    echo "Restarting SSH service..."
    if command -v systemctl >/dev/null 2>&1; then
        # Linux with systemd
        if systemctl is-active sshd >/dev/null 2>&1; then
            systemctl restart sshd
            echo "✓ SSH service restarted (sshd)"
        elif systemctl is-active ssh >/dev/null 2>&1; then
            systemctl restart ssh
            echo "✓ SSH service restarted (ssh)"
        else
            echo "⚠ SSH service not running, starting it..."
            systemctl start sshd || systemctl start ssh || echo "✗ Failed to start SSH service"
        fi
    elif command -v service >/dev/null 2>&1; then
        # Linux with init.d
        service ssh restart || service sshd restart || echo "✗ Failed to restart SSH service"
    elif [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
        sudo launchctl load /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
        echo "✓ SSH service restarted on macOS"
    else
        echo "⚠ Cannot determine how to restart SSH service on this system"
    fi

    # Display SSH service status
    echo "SSH service status:"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl status sshd --no-pager -l || systemctl status ssh --no-pager -l || echo "SSH service status unknown"
    else
        echo "SSH daemon should be running. Check with: ps aux | grep sshd"
    fi

    # Show SSH configuration summary
    echo ""
    echo "SSH Configuration Summary:"
    echo "- Password authentication: DISABLED"
    echo "- Root login: DISABLED"
    echo "- Empty passwords: DISABLED"
    echo "- Max auth tries: 3"
    echo "- Protocol: 2"
    echo ""
    echo "⚠ IMPORTANT: Make sure you have SSH key authentication configured"
    echo "   before logging out, as password authentication is now disabled!"
    echo ""
    echo "To add your SSH key:"
    echo "  mkdir -p ~/.ssh"
    echo "  echo 'your-public-key-here' >> ~/.ssh/authorized_keys"
    echo "  chmod 700 ~/.ssh"
    echo "  chmod 600 ~/.ssh/authorized_keys"
}

# run main
krun::config::ssh::run "$@"
