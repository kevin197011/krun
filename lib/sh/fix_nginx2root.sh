#!/usr/bin/env bash
# Copyright (c) 2026 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/fix_nginx2root.sh | sudo bash
#
# NGINX2Root fix (https://nginx2root.com): force-upgrade to latest nginx.org
# mainline security build, restart, block SCTP.
# Env: MITIGATE_ONLY=1  SKIP_SCTP=1

# vars
MITIGATE_ONLY="${MITIGATE_ONLY:-0}"
SKIP_SCTP="${SKIP_SCTP:-0}"

# run code
krun::fix::nginx2root::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos / rocky / rhel
krun::fix::nginx2root::centos() {
    echo "Fixing NGINX2Root on Rocky/RHEL/Alma..."

    [[ "$OSTYPE" != "darwin"* ]] && [[ $EUID -ne 0 ]] && echo "✗ Please run as root" && return 1

    if [[ "$MITIGATE_ONLY" == "1" ]]; then
        krun::fix::nginx2root::mitigate_http2
        krun::fix::nginx2root::common
        return 0
    fi

    if command -v dnf >/dev/null 2>&1; then
        dnf install -y yum-utils
    else
        yum install -y yum-utils
    fi

    # mainline = latest security release from nginx.org
    cat >/etc/yum.repos.d/nginx.repo <<'EOF'
[nginx-mainline]
name=nginx mainline repo
baseurl=https://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF

    echo "↑ Force upgrade nginx to latest security build (nginx.org mainline)..."
    # Rocky/RHEL appstream nginx-mod-* pins nginx(abi)=1.20.x and blocks ngx packages
    krun::fix::nginx2root::purge_distro_mods

    if command -v dnf >/dev/null 2>&1; then
        dnf module disable nginx -y 2>/dev/null || true
        dnf clean metadata
        dnf makecache
        dnf install -y nginx --allowerasing
        dnf upgrade -y nginx --allowerasing
    else
        yum clean metadata
        yum makecache
        yum install -y nginx --allowerasing
        yum update -y nginx --allowerasing
    fi

    krun::fix::nginx2root::common
}

# debian / ubuntu
krun::fix::nginx2root::debian() {
    echo "Fixing NGINX2Root on Ubuntu/Debian..."

    [[ "$OSTYPE" != "darwin"* ]] && [[ $EUID -ne 0 ]] && echo "✗ Please run as root" && return 1

    if [[ "$MITIGATE_ONLY" == "1" ]]; then
        krun::fix::nginx2root::mitigate_http2
        krun::fix::nginx2root::common
        return 0
    fi

    . /etc/os-release
    local distro="$ID"
    local codename="${VERSION_CODENAME:-}"
    command -v lsb_release >/dev/null 2>&1 && codename="$(lsb_release -cs)"
    [[ -n "$codename" ]] || {
        echo "✗ Cannot detect distro codename" >&2
        return 1
    }

    case "$distro" in
        ubuntu)
            apt-get install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring
            ;;
        debian)
            apt-get install -y curl gnupg2 ca-certificates lsb-release debian-archive-keyring
            ;;
        *)
            echo "✗ Unsupported ID=$distro (need ubuntu/debian)" >&2
            return 1
            ;;
    esac

    curl -fsSL https://nginx.org/keys/nginx_signing.key |
        gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg

    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] https://nginx.org/packages/mainline/${distro} ${codename} nginx" \
        >/etc/apt/sources.list.d/nginx.list

    cat >/etc/apt/preferences.d/99nginx <<'EOF'
Package: *
Pin: origin nginx.org
Pin: release o=nginx
Pin-Priority: 900
EOF

    export DEBIAN_FRONTEND=noninteractive
    echo "↑ Force upgrade nginx to latest security build (nginx.org mainline)..."
    apt-get update -qq
    apt-get install -y nginx
    apt-get install -y --only-upgrade nginx || true

    krun::fix::nginx2root::common
}

# mac
krun::fix::nginx2root::mac() {
    echo "✗ macOS not supported (use Rocky/Ubuntu)"
    return 1
}

# Drop Rocky/RHEL nginx-mod-* (ABI lock on distro nginx 1.20.x)
krun::fix::nginx2root::purge_distro_mods() {
    local pkgs
    pkgs="$(rpm -qa 'nginx-mod-*' 2>/dev/null || true)"
    [[ -n "$pkgs" ]] || return 0

    echo "↑ Removing distro nginx-mod-* (ABI conflict with nginx.org)..."
    # shellcheck disable=SC2086
    if command -v dnf >/dev/null 2>&1; then
        dnf remove -y $pkgs || dnf remove -y 'nginx-mod-*' || true
    else
        yum remove -y $pkgs || yum remove -y 'nginx-mod-*' || true
    fi
}

# common: SCTP block + restart + verify
krun::fix::nginx2root::common() {
    krun::fix::nginx2root::block_sctp

    if command -v nginx >/dev/null 2>&1 && command -v systemctl >/dev/null 2>&1; then
        systemctl enable nginx 2>/dev/null || true
        # reload keeps old binary — must restart
        systemctl restart nginx
        if systemctl is-active --quiet nginx; then
            echo "✓ nginx restarted"
        else
            echo "✗ nginx failed to start" >&2
            systemctl status nginx --no-pager || true
            return 1
        fi
    fi

    if [[ "$MITIGATE_ONLY" != "1" ]]; then
        command -v nginx >/dev/null || {
            echo "✗ nginx missing after install" >&2
            return 1
        }
        if ! krun::fix::nginx2root::is_fixed; then
            echo "✗ Still vulnerable: $(nginx -v 2>&1) (need >=1.31.9)" >&2
            return 1
        fi
    fi

    if command -v nginx >/dev/null 2>&1; then
        echo "✓ NGINX2Root fix done: $(nginx -v 2>&1)"
    else
        echo "✓ NGINX2Root mitigate done (nginx not installed)"
    fi
}

# Fixed: >=1.31.9 (mainline security), or >=1.30.7 on 1.30.x
krun::fix::nginx2root::is_fixed() {
    command -v nginx >/dev/null 2>&1 || return 1
    local ver
    ver="$(nginx -v 2>&1 | sed -n 's/.*nginx\/\([0-9.]*\).*/\1/p')"
    [[ -n "$ver" ]] || return 1

    krun::fix::nginx2root::ver_ge "$ver" "1.31.9" && return 0
    krun::fix::nginx2root::ver_ge "$ver" "1.30.7" || return 1
    krun::fix::nginx2root::ver_ge "$ver" "1.31.0" && return 1
    return 0
}

krun::fix::nginx2root::ver_ge() {
    [[ "$(printf '%s\n' "$1" "$2" | sort -V | head -1)" == "$2" ]]
}

# Temporary: turn off HTTP/2 (covers CVE-2026-123007 + 123633 only)
krun::fix::nginx2root::mitigate_http2() {
    [[ -d /etc/nginx ]] || {
        echo "⚠ /etc/nginx missing — skip HTTP/2 mitigate"
        return 0
    }

    local changed=0 f
    while IFS= read -r -d '' f; do
        grep -qE 'listen[[:space:]].*http2|http2[[:space:]]+on' "$f" || continue
        cp -a "$f" "${f}.bak.nginx2root"
        sed -i -E 's/(listen[[:space:]][^;]*)[[:space:]]+http2/\1/g' "$f"
        sed -i -E 's/http2[[:space:]]+on[[:space:]]*;/http2 off;/g' "$f"
        changed=1
        echo "✓ HTTP/2 disabled: $f"
    done < <(find /etc/nginx -type f -name '*.conf' -print0 2>/dev/null)

    [[ "$changed" -eq 0 ]] && echo "✓ No HTTP/2 directives found"
    command -v nginx >/dev/null 2>&1 && nginx -t
}

krun::fix::nginx2root::block_sctp() {
    if [[ "$SKIP_SCTP" == "1" ]]; then
        echo "⚠ SKIP_SCTP=1 — skip SCTP block"
        return 0
    fi

    mkdir -p /etc/modprobe.d
    cat >/etc/modprobe.d/disable-sctp.conf <<'EOF'
# NGINX2Root: block SCTP until kernel LPE is patched
install sctp /bin/false
blacklist sctp
EOF

    if lsmod 2>/dev/null | grep -q '^sctp\b'; then
        rmmod sctp 2>/dev/null || echo "⚠ sctp loaded — reboot to unload"
    fi
    echo "✓ SCTP blocked (/etc/modprobe.d/disable-sctp.conf)"
}

# run main
krun::fix::nginx2root::run "$@"
