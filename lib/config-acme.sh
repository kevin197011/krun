#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-acme.sh | bash

# vars
ACME_EMAIL="${ACME_EMAIL:-kevin197011@outlook.com}"
ACME_HOME="${HOME}/.acme.sh"
ACME_BIN="${ACME_HOME}/acme.sh"

# run code
krun::config::acme::run() {
    local action="${1:-install}"
    shift || true

    case "$action" in
    install)
        krun::config::acme::install "$@"
        ;;
    issue)
        krun::config::acme::issue "$@"
        ;;
    install-cert)
        krun::config::acme::install_cert "$@"
        ;;
    renew)
        krun::config::acme::renew "$@"
        ;;
    list)
        krun::config::acme::list "$@"
        ;;
    revoke)
        krun::config::acme::revoke "$@"
        ;;
    *)
        krun::config::acme::usage
        exit 1
        ;;
    esac
}

# usage
krun::config::acme::usage() {
    cat <<EOF
Usage: $0 <action> [options]

Actions:
  install                    - Install acme.sh
  issue <domain> [options]   - Issue SSL certificate
  install-cert <domain>       - Install certificate to web server
  renew [domain]             - Renew certificate(s)
  list                       - List all certificates
  revoke <domain>            - Revoke certificate

Examples:
  # Install acme.sh
  $0 install

  # Issue certificate using DNS (Cloudflare)
  export CF_Email="your@email.com"
  export CF_Key="your_api_key"
  $0 issue example.com --dns dns_cf

  # Issue certificate using HTTP
  $0 issue example.com --webroot /var/www/html

  # Issue wildcard certificate
  $0 issue example.com --dns dns_cf --domain "*.example.com"

  # Install certificate to Nginx
  $0 install-cert example.com --nginx

  # Install certificate to Apache
  $0 install-cert example.com --apache

  # Install certificate to custom path
  $0 install-cert example.com \\
    --key-file /etc/ssl/private/example.com.key \\
    --fullchain-file /etc/ssl/certs/example.com.crt \\
    --reloadcmd "systemctl reload nginx"

  # Renew all certificates
  $0 renew

  # Renew specific certificate
  $0 renew example.com

  # List all certificates
  $0 list

  # Revoke certificate
  $0 revoke example.com
EOF
}

# install acme.sh
krun::config::acme::install() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "krun::config::acme::install::${platform}"
}

# centos install
krun::config::acme::install::centos() {
    echo "Installing acme.sh on CentOS/RHEL..."

    # Install dependencies
    yum install -y curl socat >/dev/null 2>&1 || dnf install -y curl socat >/dev/null 2>&1 || true

    # Install acme.sh
    if [[ ! -f "$ACME_BIN" ]]; then
        echo "Downloading and installing acme.sh..."
        curl -sf https://get.acme.sh | sh -s email="${ACME_EMAIL}" || {
            echo "Error: Failed to install acme.sh" >&2
            exit 1
        }
    else
        echo "acme.sh is already installed at $ACME_BIN"
    fi

    # Upgrade and enable auto-upgrade
    "$ACME_BIN" --upgrade --auto-upgrade >/dev/null 2>&1 || true

    echo "✓ acme.sh installed successfully"
    echo "  Location: $ACME_BIN"
    echo "  Email: ${ACME_EMAIL}"
}

# debian install
krun::config::acme::install::debian() {
    echo "Installing acme.sh on Debian/Ubuntu..."

    # Install dependencies
    apt-get update >/dev/null 2>&1
    apt-get install -y curl socat >/dev/null 2>&1 || true

    # Install acme.sh
    if [[ ! -f "$ACME_BIN" ]]; then
        echo "Downloading and installing acme.sh..."
        curl -sf https://get.acme.sh | sh -s email="${ACME_EMAIL}" || {
            echo "Error: Failed to install acme.sh" >&2
            exit 1
        }
    else
        echo "acme.sh is already installed at $ACME_BIN"
    fi

    # Upgrade and enable auto-upgrade
    "$ACME_BIN" --upgrade --auto-upgrade >/dev/null 2>&1 || true

    echo "✓ acme.sh installed successfully"
    echo "  Location: $ACME_BIN"
    echo "  Email: ${ACME_EMAIL}"
}

# mac install
krun::config::acme::install::mac() {
    echo "Installing acme.sh on macOS..."

    # Install dependencies
    if ! command -v socat >/dev/null 2>&1; then
        if command -v brew >/dev/null 2>&1; then
            brew install socat >/dev/null 2>&1 || true
        else
            echo "Warning: socat not found. Please install it manually: brew install socat"
        fi
    fi

    # Install acme.sh
    if [[ ! -f "$ACME_BIN" ]]; then
        echo "Downloading and installing acme.sh..."
        curl -sf https://get.acme.sh | sh -s email="${ACME_EMAIL}" || {
            echo "Error: Failed to install acme.sh" >&2
            exit 1
        }
    else
        echo "acme.sh is already installed at $ACME_BIN"
    fi

    # Upgrade and enable auto-upgrade
    "$ACME_BIN" --upgrade --auto-upgrade >/dev/null 2>&1 || true

    echo "✓ acme.sh installed successfully"
    echo "  Location: $ACME_BIN"
    echo "  Email: ${ACME_EMAIL}"
}

# issue certificate
krun::config::acme::issue() {
    local domain="${1:-}"
    if [[ -z "$domain" ]]; then
        echo "Error: Domain is required" >&2
        echo "Usage: $0 issue <domain> [--dns <dns_provider>] [--webroot <path>] [--domain <additional_domain>]" >&2
        exit 1
    fi

    shift || true

    # Check if acme.sh is installed
    if [[ ! -f "$ACME_BIN" ]]; then
        echo "Error: acme.sh is not installed. Please run: $0 install" >&2
        exit 1
    fi

    local dns_provider=""
    local webroot=""
    local additional_domains=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --dns)
            dns_provider="$2"
            shift 2
            ;;
        --webroot)
            webroot="$2"
            shift 2
            ;;
        --domain)
            additional_domains="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        esac
    done

    echo "Issuing SSL certificate for domain: $domain"

    # Build acme.sh command
    local cmd="$ACME_BIN --issue"

    if [[ -n "$dns_provider" ]]; then
        # DNS validation
        echo "Using DNS validation with provider: $dns_provider"
        cmd="$cmd --dns $dns_provider"
    elif [[ -n "$webroot" ]]; then
        # HTTP validation with webroot
        echo "Using HTTP validation with webroot: $webroot"
        cmd="$cmd --webroot $webroot"
    else
        # Standalone mode (requires port 80 to be free)
        echo "Using standalone mode (port 80 must be available)"
        cmd="$cmd --standalone"
    fi

    # Add domain
    cmd="$cmd -d $domain"

    # Add additional domains if specified
    if [[ -n "$additional_domains" ]]; then
        cmd="$cmd -d $additional_domains"
    fi

    # Execute
    echo "Executing: $cmd"
    eval "$cmd" || {
        echo "Error: Failed to issue certificate" >&2
        exit 1
    }

    echo "✓ Certificate issued successfully for $domain"
}

# install certificate
krun::config::acme::install_cert() {
    local domain="${1:-}"
    if [[ -z "$domain" ]]; then
        echo "Error: Domain is required" >&2
        echo "Usage: $0 install-cert <domain> [options]" >&2
        exit 1
    fi

    shift || true

    # Check if acme.sh is installed
    if [[ ! -f "$ACME_BIN" ]]; then
        echo "Error: acme.sh is not installed. Please run: $0 install" >&2
        exit 1
    fi

    # Check if certificate exists
    if [[ ! -d "${ACME_HOME}/${domain}" ]]; then
        echo "Error: Certificate for $domain not found. Please issue it first: $0 issue $domain" >&2
        exit 1
    fi

    local key_file=""
    local fullchain_file=""
    local ca_file=""
    local reloadcmd=""
    local nginx_path=""
    local apache_path=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --key-file)
            key_file="$2"
            shift 2
            ;;
        --fullchain-file)
            fullchain_file="$2"
            shift 2
            ;;
        --ca-file)
            ca_file="$2"
            shift 2
            ;;
        --reloadcmd)
            reloadcmd="$2"
            shift 2
            ;;
        --nginx)
            nginx_path="/etc/nginx/ssl/${domain}"
            shift
            ;;
        --apache)
            apache_path="/etc/apache2/ssl/${domain}"
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        esac
    done

    # Auto-detect web server if not specified
    if [[ -z "$key_file" ]] && [[ -z "$nginx_path" ]] && [[ -z "$apache_path" ]]; then
        if command -v nginx >/dev/null 2>&1; then
            nginx_path="/etc/nginx/ssl/${domain}"
            echo "Auto-detected Nginx, using path: $nginx_path"
        elif command -v apache2 >/dev/null 2>&1 || command -v httpd >/dev/null 2>&1; then
            apache_path="/etc/apache2/ssl/${domain}"
            echo "Auto-detected Apache, using path: $apache_path"
        fi
    fi

    # Set default paths
    if [[ -n "$nginx_path" ]]; then
        mkdir -p "$nginx_path"
        key_file="${nginx_path}/${domain}.key"
        fullchain_file="${nginx_path}/${domain}.crt"
        reloadcmd="systemctl reload nginx || service nginx reload"
    elif [[ -n "$apache_path" ]]; then
        mkdir -p "$apache_path"
        key_file="${apache_path}/${domain}.key"
        fullchain_file="${apache_path}/${domain}.crt"
        reloadcmd="systemctl reload apache2 || systemctl reload httpd || service apache2 reload || service httpd reload"
    elif [[ -z "$key_file" ]] || [[ -z "$fullchain_file" ]]; then
        # Default paths
        key_file="${key_file:-/etc/ssl/private/${domain}.key}"
        fullchain_file="${fullchain_file:-/etc/ssl/certs/${domain}.crt}"
        reloadcmd="${reloadcmd:-echo 'Certificate installed, please reload your web server manually'}"
    fi

    # Create directories
    mkdir -p "$(dirname "$key_file")"
    mkdir -p "$(dirname "$fullchain_file")"

    # Build install command
    local cmd="$ACME_BIN --install-cert -d $domain"
    cmd="$cmd --key-file $key_file"
    cmd="$cmd --fullchain-file $fullchain_file"

    if [[ -n "$ca_file" ]]; then
        mkdir -p "$(dirname "$ca_file")"
        cmd="$cmd --ca-file $ca_file"
    fi

    if [[ -n "$reloadcmd" ]]; then
        cmd="$cmd --reloadcmd \"$reloadcmd\""
    fi

    # Execute
    echo "Installing certificate for $domain..."
    echo "  Key file: $key_file"
    echo "  Certificate file: $fullchain_file"
    eval "$cmd" || {
        echo "Error: Failed to install certificate" >&2
        exit 1
    }

    echo "✓ Certificate installed successfully"
    echo "  Domain: $domain"
    echo "  Key: $key_file"
    echo "  Certificate: $fullchain_file"
}

# renew certificate
krun::config::acme::renew() {
    local domain="${1:-}"

    # Check if acme.sh is installed
    if [[ ! -f "$ACME_BIN" ]]; then
        echo "Error: acme.sh is not installed. Please run: $0 install" >&2
        exit 1
    fi

    if [[ -n "$domain" ]]; then
        echo "Renewing certificate for: $domain"
        "$ACME_BIN" --renew -d "$domain" || {
            echo "Error: Failed to renew certificate for $domain" >&2
            exit 1
        }
        echo "✓ Certificate renewed successfully for $domain"
    else
        echo "Renewing all certificates..."
        "$ACME_BIN" --renew-all || {
            echo "Error: Failed to renew certificates" >&2
            exit 1
        }
        echo "✓ All certificates renewed successfully"
    fi
}

# list certificates
krun::config::acme::list() {
    # Check if acme.sh is installed
    if [[ ! -f "$ACME_BIN" ]]; then
        echo "Error: acme.sh is not installed. Please run: $0 install" >&2
        exit 1
    fi

    echo "List of certificates:"
    "$ACME_BIN" --list || {
        echo "No certificates found or error occurred" >&2
        exit 1
    }
}

# revoke certificate
krun::config::acme::revoke() {
    local domain="${1:-}"
    if [[ -z "$domain" ]]; then
        echo "Error: Domain is required" >&2
        echo "Usage: $0 revoke <domain>" >&2
        exit 1
    fi

    # Check if acme.sh is installed
    if [[ ! -f "$ACME_BIN" ]]; then
        echo "Error: acme.sh is not installed. Please run: $0 install" >&2
        exit 1
    fi

    echo "Revoking certificate for: $domain"
    "$ACME_BIN" --revoke -d "$domain" || {
        echo "Error: Failed to revoke certificate for $domain" >&2
        exit 1
    }
    echo "✓ Certificate revoked successfully for $domain"
}

# run main
krun::config::acme::run "$@"
