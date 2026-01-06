#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/check-system-baseline.sh | bash

# vars
PASS_COUNT=0
FAIL_COUNT=0

# run code
krun::check::system_baseline::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::check::system_baseline::centos() {
    krun::check::system_baseline::common
}

# debian code
krun::check::system_baseline::debian() {
    krun::check::system_baseline::common
}

# mac code
krun::check::system_baseline::mac() {
    echo "System baseline check not fully supported on macOS"
    krun::check::system_baseline::common
}

# check function
krun::check::system_baseline::check() {
    local item="$1"
    local result="$2"
    local description="$3"

    if [[ "$result" == "PASS" ]] || [[ "$result" == "true" ]] || [[ "$result" == "0" ]]; then
        echo "✓ $item: $description"
        ((PASS_COUNT++)) || true
    else
        echo "✗ $item: $description"
        ((FAIL_COUNT++)) || true
    fi
}

# common code
krun::check::system_baseline::common() {
    echo "System Baseline Check"
    echo "===================="
    echo ""

    # SSH Configuration Checks
    echo "=== SSH Security ==="
    if [[ -f /etc/ssh/sshd_config ]]; then
        if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config || grep -q "^PermitRootLogin.*no" /etc/ssh/sshd_config; then
            krun::check::system_baseline::check "SSH" "PASS" "Root login disabled"
        else
            krun::check::system_baseline::check "SSH" "FAIL" "Root login should be disabled"
        fi

        if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config || grep -q "^PasswordAuthentication.*no" /etc/ssh/sshd_config; then
            krun::check::system_baseline::check "SSH" "PASS" "Password authentication disabled"
        else
            krun::check::system_baseline::check "SSH" "FAIL" "Password authentication should be disabled"
        fi

        if grep -q "^Protocol 2" /etc/ssh/sshd_config; then
            krun::check::system_baseline::check "SSH" "PASS" "Protocol 2 enabled"
        else
            krun::check::system_baseline::check "SSH" "FAIL" "Should use Protocol 2"
        fi
    else
        krun::check::system_baseline::check "SSH" "FAIL" "SSH config file not found"
    fi
    echo ""

    # Kernel Security Parameters
    echo "=== Kernel Security ==="
    if sysctl net.ipv4.ip_forward 2>/dev/null | grep -q "= 0"; then
        krun::check::system_baseline::check "Kernel" "PASS" "IP forwarding disabled"
    else
        krun::check::system_baseline::check "Kernel" "FAIL" "IP forwarding should be disabled"
    fi

    if sysctl net.ipv4.tcp_syncookies 2>/dev/null | grep -q "= 1"; then
        krun::check::system_baseline::check "Kernel" "PASS" "TCP SYN cookies enabled"
    else
        krun::check::system_baseline::check "Kernel" "FAIL" "TCP SYN cookies should be enabled"
    fi

    if sysctl kernel.randomize_va_space 2>/dev/null | grep -q "= 2"; then
        krun::check::system_baseline::check "Kernel" "PASS" "ASLR enabled"
    else
        krun::check::system_baseline::check "Kernel" "FAIL" "ASLR should be enabled"
    fi
    echo ""

    # File Permissions
    echo "=== File Permissions ==="
    if [[ -f /etc/passwd ]] && [[ $(stat -c "%a" /etc/passwd 2>/dev/null || stat -f "%OLp" /etc/passwd 2>/dev/null) == "644" ]]; then
        krun::check::system_baseline::check "Files" "PASS" "/etc/passwd permissions correct"
    else
        krun::check::system_baseline::check "Files" "FAIL" "/etc/passwd should be 644"
    fi

    if [[ -f /etc/shadow ]] && [[ $(stat -c "%a" /etc/shadow 2>/dev/null || stat -f "%OLp" /etc/shadow 2>/dev/null) == "600" ]] || [[ $(stat -c "%a" /etc/shadow 2>/dev/null || stat -f "%OLp" /etc/shadow 2>/dev/null) == "0" ]]; then
        krun::check::system_baseline::check "Files" "PASS" "/etc/shadow permissions correct"
    else
        krun::check::system_baseline::check "Files" "FAIL" "/etc/shadow should be 600"
    fi

    if [[ -f /etc/ssh/sshd_config ]] && [[ $(stat -c "%a" /etc/ssh/sshd_config 2>/dev/null || stat -f "%OLp" /etc/ssh/sshd_config 2>/dev/null) == "600" ]]; then
        krun::check::system_baseline::check "Files" "PASS" "/etc/ssh/sshd_config permissions correct"
    else
        krun::check::system_baseline::check "Files" "FAIL" "/etc/ssh/sshd_config should be 600"
    fi
    echo ""

    # Password Policy
    echo "=== Password Policy ==="
    if [[ -f /etc/login.defs ]]; then
        if grep -q "^PASS_MAX_DAYS.*90" /etc/login.defs || grep -q "^PASS_MAX_DAYS.*[1-8][0-9]" /etc/login.defs || grep -q "^PASS_MAX_DAYS.*9[0-9]" /etc/login.defs; then
            krun::check::system_baseline::check "Password" "PASS" "Password max days configured"
        else
            krun::check::system_baseline::check "Password" "FAIL" "Password max days should be <= 90"
        fi

        if grep -q "^PASS_MIN_DAYS.*[1-9]" /etc/login.defs; then
            krun::check::system_baseline::check "Password" "PASS" "Password min days configured"
        else
            krun::check::system_baseline::check "Password" "FAIL" "Password min days should be >= 1"
        fi
    fi
    echo ""

    # Service Status
    echo "=== Service Status ==="
    if [[ "$OSTYPE" != "darwin"* ]]; then
        if systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null; then
            krun::check::system_baseline::check "Services" "PASS" "SSH service running"
        else
            krun::check::system_baseline::check "Services" "FAIL" "SSH service should be running"
        fi

        if systemctl is-enabled --quiet sshd 2>/dev/null || systemctl is-enabled --quiet ssh 2>/dev/null; then
            krun::check::system_baseline::check "Services" "PASS" "SSH service enabled"
        else
            krun::check::system_baseline::check "Services" "FAIL" "SSH service should be enabled"
        fi

        if ! systemctl is-active --quiet avahi-daemon 2>/dev/null; then
            krun::check::system_baseline::check "Services" "PASS" "Unnecessary service (avahi) disabled"
        else
            krun::check::system_baseline::check "Services" "FAIL" "avahi-daemon should be disabled"
        fi
    fi
    echo ""

    # Firewall Status (if available)
    echo "=== Firewall ==="
    if [[ "$OSTYPE" != "darwin"* ]]; then
        if command -v firewall-cmd >/dev/null 2>&1; then
            if firewall-cmd --state 2>/dev/null | grep -q "running"; then
                krun::check::system_baseline::check "Firewall" "PASS" "firewalld is running"
            else
                krun::check::system_baseline::check "Firewall" "FAIL" "firewalld should be running"
            fi
        elif command -v ufw >/dev/null 2>&1; then
            if ufw status 2>/dev/null | grep -q "Status: active"; then
                krun::check::system_baseline::check "Firewall" "PASS" "ufw is active"
            else
                krun::check::system_baseline::check "Firewall" "FAIL" "ufw should be active"
            fi
        elif command -v iptables >/dev/null 2>&1; then
            if iptables -L | grep -q "INPUT.*DROP\|INPUT.*REJECT" 2>/dev/null; then
                krun::check::system_baseline::check "Firewall" "PASS" "iptables rules configured"
            else
                krun::check::system_baseline::check "Firewall" "FAIL" "iptables rules should be configured"
            fi
        else
            krun::check::system_baseline::check "Firewall" "FAIL" "No firewall detected"
        fi
    fi
    echo ""

    # Summary
    echo "===================="
    echo "Check Summary"
    echo "===================="
    echo "Passed: $PASS_COUNT"
    echo "Failed: $FAIL_COUNT"
    echo "Total:  $((PASS_COUNT + FAIL_COUNT))"
    echo ""

    if [[ $FAIL_COUNT -eq 0 ]]; then
        echo "✓ All checks passed!"
        exit 0
    else
        echo "✗ Some checks failed. Please review and fix the issues."
        exit 1
    fi
}

# run main
krun::check::system_baseline::run "$@"
