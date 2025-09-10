#!/usr/bin/env bash

# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-system-baseline.sh | bash

# vars

# run code
krun::config::system_baseline::run() {
    # default debian platform
    platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::system_baseline::centos() {
    echo "Configuring system baseline on CentOS/RHEL..."

    # Update system
    yum update -y
    yum install -y epel-release

    # Install security tools
    yum install -y aide auditd rsyslog fail2ban rkhunter

    krun::config::system_baseline::common
}

# debian code
krun::config::system_baseline::debian() {
    echo "Configuring system baseline on Debian/Ubuntu..."

    # Update system
    apt-get update
    apt-get upgrade -y

    # Install security tools
    apt-get install -y aide auditd rsyslog fail2ban rkhunter chkrootkit

    krun::config::system_baseline::common
}

# mac code
krun::config::system_baseline::mac() {
    echo "System baseline configuration not supported on macOS"
    exit 1
}

# common code
krun::config::system_baseline::common() {
    echo "Applying common security baseline..."

    # Backup original configs
    mkdir -p /root/baseline-backup-$(date +%Y%m%d)
    cp /etc/ssh/sshd_config /root/baseline-backup-$(date +%Y%m%d)/ 2>/dev/null || true
    cp /etc/sysctl.conf /root/baseline-backup-$(date +%Y%m%d)/ 2>/dev/null || true

    # Configure kernel security parameters
    tee /etc/sysctl.d/99-security-baseline.conf >/dev/null <<EOF
# Network Security Parameters
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1

# Kernel Security
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.randomize_va_space = 2
fs.suid_dumpable = 0
EOF

    sysctl -p /etc/sysctl.d/99-security-baseline.conf

    # Configure SSH security
    perl -pi -e 's/^#?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    perl -pi -e 's/^#?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    perl -pi -e 's/^#?MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
    perl -pi -e 's/^#?X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config

    grep -q "^Protocol 2" /etc/ssh/sshd_config || echo "Protocol 2" >>/etc/ssh/sshd_config
    grep -q "^ClientAliveInterval" /etc/ssh/sshd_config || echo "ClientAliveInterval 300" >>/etc/ssh/sshd_config
    grep -q "^ClientAliveCountMax" /etc/ssh/sshd_config || echo "ClientAliveCountMax 2" >>/etc/ssh/sshd_config

    # Create warning banner
    tee /etc/issue.net >/dev/null <<EOF
Authorized users only. All activity may be monitored and reported.
EOF

    # Test and restart SSH
    sshd -t && systemctl restart sshd

    # Configure basic logging
    systemctl enable rsyslog
    systemctl start rsyslog

    # Configure log rotation
    tee /etc/logrotate.d/security-logs >/dev/null <<EOF
/var/log/auth.log
/var/log/secure {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}
EOF

    # Configure basic audit rules
    systemctl enable auditd
    systemctl start auditd

    # Add basic audit rules
    tee /etc/audit/rules.d/baseline.rules >/dev/null <<EOF
# Basic audit rules
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k scope
-w /var/log/faillog -p wa -k logins
-w /var/log/lastlog -p wa -k logins
EOF

    service auditd restart 2>/dev/null || systemctl restart auditd

    # Set secure file permissions
    chmod 644 /etc/passwd
    chmod 600 /etc/shadow
    chmod 644 /etc/group
    chmod 600 /etc/ssh/sshd_config
    chmod 600 /etc/crontab

    # Configure password policy
    perl -pi -e 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
    perl -pi -e 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/' /etc/login.defs
    perl -pi -e 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs

    # Disable unnecessary services
    local services_to_disable=(
        "avahi-daemon"
        "cups"
        "bluetooth"
        "rpcbind"
        "nfs"
    )

    for service in "${services_to_disable[@]}"; do
        systemctl disable "$service" 2>/dev/null || true
        systemctl stop "$service" 2>/dev/null || true
    done

    # Initialize AIDE if available
    if command -v aide >/dev/null 2>&1; then
        aide --init 2>/dev/null || true
        mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz 2>/dev/null || true
    fi

    echo "System baseline configuration completed"
    echo "IMPORTANT: Reboot recommended to apply all changes"
    echo "WARNING: SSH password authentication disabled - ensure key auth is configured"
}

# run main
krun::config::system_baseline::run "$@"
