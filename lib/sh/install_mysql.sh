#!/usr/bin/env bash
# Copyright (c) 2026 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_mysql.sh | sudo bash
#
# MySQL 8.4 LTS (community). Re-run is safe: already-8 installs only restart the service.
# MYSQL_ROOT_PASSWORD=...  set root password after first start (must meet policy)

# vars
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-}"

# run code
krun::install::mysql::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

krun::install::mysql::already() {
    command -v mysqld >/dev/null 2>&1 && mysqld --version 2>/dev/null | grep -q 'Ver 8\.'
}

krun::install::mysql::centos() {
    [[ "$(id -u)" -eq 0 ]] || {
        echo "✗ Please run as root"
        exit 1
    }
    if krun::install::mysql::already; then
        echo "✓ MySQL 8 already installed"
        krun::install::mysql::common
        return
    fi

    local el
    el=$(. /etc/os-release && echo "${VERSION_ID%%.*}")
    local rpm=""
    case "$el" in
    7) rpm="https://repo.mysql.com/mysql84-community-release-el7-1.noarch.rpm" ;;
    8) rpm="https://repo.mysql.com/mysql84-community-release-el8-1.noarch.rpm" ;;
    9) rpm="https://repo.mysql.com/mysql84-community-release-el9-1.noarch.rpm" ;;
    *)
        echo "✗ unsupported RHEL major: ${el:-unknown} (need 7/8/9)"
        exit 1
        ;;
    esac

    local pm="yum"
    command -v dnf >/dev/null && pm="dnf"
    rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 || true
    rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2025 || true
    $pm module disable -y mysql >/dev/null 2>&1 || true
    $pm install -y "$rpm"
    $pm install -y mysql-community-server mysql-community-client
    krun::install::mysql::common
}

krun::install::mysql::debian() {
    [[ "$(id -u)" -eq 0 ]] || {
        echo "✗ Please run as root"
        exit 1
    }
    if krun::install::mysql::already; then
        echo "✓ MySQL 8 already installed"
        krun::install::mysql::common
        return
    fi

    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y ca-certificates curl gnupg
    . /etc/os-release
    local family="debian" codename="${VERSION_CODENAME:-}"
    [[ "${ID:-}" == "ubuntu" || "${ID_LIKE:-}" == *ubuntu* ]] && family="ubuntu"
    [[ -n "$codename" ]] || {
        echo "✗ cannot read VERSION_CODENAME"
        exit 1
    }

    install -d /usr/share/keyrings
    rm -f /usr/share/keyrings/mysql-2023.gpg /usr/share/keyrings/mysql-2025.gpg /usr/share/keyrings/mysql.gpg
    curl -fsSL https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 | gpg --dearmor -o /usr/share/keyrings/mysql-2023.gpg
    curl -fsSL https://repo.mysql.com/RPM-GPG-KEY-mysql-2025 | gpg --dearmor -o /usr/share/keyrings/mysql-2025.gpg
    cat /usr/share/keyrings/mysql-2023.gpg /usr/share/keyrings/mysql-2025.gpg >/usr/share/keyrings/mysql.gpg
    echo "deb [signed-by=/usr/share/keyrings/mysql.gpg] https://repo.mysql.com/apt/${family} ${codename} mysql-8.4-lts" \
        >/etc/apt/sources.list.d/mysql.list
    apt-get update
    apt-get install -y mysql-community-server mysql-community-client
    krun::install::mysql::common
}

krun::install::mysql::mac() {
    command -v brew >/dev/null || {
        echo "✗ Homebrew is required on macOS"
        exit 1
    }
    brew install mysql@8.4
    brew services start mysql@8.4 || true
    echo "✓ MySQL 8.4 installed via Homebrew"
    brew list --versions mysql@8.4 || true
}

krun::install::mysql::common() {
    local svc="mysqld"
    systemctl list-unit-files 2>/dev/null | grep -q '^mysql\.service' && svc="mysql"
    systemctl enable --now "$svc"
    echo "✓ MySQL service ${svc} enabled"
    mysqld --version 2>/dev/null || mysql --version || true

    local hint=""
    hint=$(grep -h 'temporary password' /var/log/mysqld.log /var/log/mysql/error.log 2>/dev/null | tail -1 || true)
    if [[ -n "$hint" ]]; then
        echo "$hint"
    fi

    if [[ -n "$MYSQL_ROOT_PASSWORD" && -n "$hint" ]]; then
        local tmp
        tmp=$(awk '{print $NF}' <<<"$hint")
        mysql --connect-expired-password -uroot -p"$tmp" -e \
            "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';" \
            && echo "✓ root password updated" \
            || echo "⚠ failed to set MYSQL_ROOT_PASSWORD (policy or already changed)"
    fi

    echo ""
    echo "MySQL 8.4 LTS is ready."
    echo "  systemctl status ${svc}"
    echo "  mysql -uroot -p"
}

krun::install::mysql::run "$@"
