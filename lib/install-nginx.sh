#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-nginx.sh | bash

# vars
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="/tmp/nginx_install_$(date +%Y%m%d_%H%M%S).log"
NGINX_VERSION=""
INSTALL_TYPE=""

# logging function
krun::install::nginx::log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >>"$LOG_FILE"

    case "$level" in
    "INFO") echo -e "${GREEN}[INFO]${NC} $message" ;;
    "WARN") echo -e "${YELLOW}[WARN]${NC} $message" ;;
    "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
    "DEBUG") echo -e "${CYAN}[DEBUG]${NC} $message" ;;
    esac
}

# error handling
krun::install::nginx::error_exit() {
    krun::install::nginx::log "ERROR" "$1"
    echo -e "${RED}Installation failed. Check log: $LOG_FILE${NC}"
    exit 1
}

# success message
krun::install::nginx::success_message() {
    echo -e "${GREEN}"
    echo "=========================================="
    echo "  🎉 Nginx Installation Completed!"
    echo "=========================================="
    echo -e "${NC}"
    echo "Installation Type: $INSTALL_TYPE"
    echo "Version: $NGINX_VERSION"
    echo "Log file: $LOG_FILE"
    echo ""
    echo "Quick Commands:"
    echo "  Start:   sudo systemctl start nginx"
    echo "  Stop:    sudo systemctl stop nginx"
    echo "  Reload:  sudo systemctl reload nginx"
    echo "  Status:  sudo systemctl status nginx"
    echo "  Test:    sudo nginx -t"
    echo ""
    echo "Default site: http://localhost"
    echo "Helper script: nginx-manage {reload|test|status|logs|access}"
}

# detect platform
krun::install::nginx::detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
        ubuntu | debian) echo "debian" ;;
        centos | rhel | rocky | almalinux) echo "rhel" ;;
        fedora) echo "fedora" ;;
        *) echo "unknown" ;;
        esac
    elif command -v yum >/dev/null 2>&1; then
        echo "rhel"
    elif command -v apt >/dev/null 2>&1; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# check root
krun::install::nginx::check_root() {
    if [[ "$OSTYPE" != "darwin"* ]] && [[ $EUID -ne 0 ]]; then
        krun::install::nginx::error_exit "This script must be run as root on Linux systems. Use: sudo $0"
    fi
}

# install dependencies
krun::install::nginx::install_dependencies() {
    local platform="$1"
    krun::install::nginx::log "INFO" "Installing dependencies for $platform..."

    case "$platform" in
    "debian")
        apt-get update -qq
        apt-get install -y curl wget gnupg2 software-properties-common lsb-release ca-certificates
        ;;
    "rhel" | "fedora")
        if command -v dnf >/dev/null 2>&1; then
            dnf install -y curl wget gnupg2 yum-utils ca-certificates
        else
            yum install -y curl wget gnupg2 yum-utils ca-certificates
        fi
        ;;
    "macos")
        if ! command -v brew >/dev/null 2>&1; then
            krun::install::nginx::error_exit "Homebrew is required for macOS installation"
        fi
        ;;
    esac
}

# debian code
krun::install::nginx::debian() {
    krun::install::nginx::log "INFO" "Installing Nginx on Debian/Ubuntu..."

    # Add official Nginx repository for latest version
    curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

    local codename=$(lsb_release -cs)
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu $codename nginx" >/etc/apt/sources.list.d/nginx.list

    # Set repository pinning to ensure we use nginx.org packages
    cat >/etc/apt/preferences.d/99nginx <<EOF
Package: *
Pin: origin nginx.org
Pin: release o=nginx
Pin-Priority: 900
EOF

    apt-get update -qq
    apt-get install -y nginx

    INSTALL_TYPE="Official Nginx (nginx.org)"
    NGINX_VERSION=$(nginx -v 2>&1 | grep -o '[0-9.]*')

    krun::install::nginx::common
}

# centos code
krun::install::nginx::centos() {
    krun::install::nginx::log "INFO" "Installing Nginx on RHEL/CentOS/Rocky/AlmaLinux/Fedora..."

    # Remove any existing nginx installations to avoid conflicts
    krun::install::nginx::log "INFO" "Removing any existing nginx packages..."
    if command -v dnf >/dev/null 2>&1; then
        dnf remove -y nginx nginx-core nginx-common nginx-module-* 2>/dev/null || true
    else
        yum remove -y nginx nginx-core nginx-common nginx-module-* 2>/dev/null || true
    fi

    # Stop any running nginx service
    systemctl stop nginx 2>/dev/null || true
    systemctl disable nginx 2>/dev/null || true

    # Backup and remove existing nginx configuration to avoid conflicts
    if [[ -d /etc/nginx ]]; then
        krun::install::nginx::log "INFO" "Backing up existing nginx configuration..."
        mv /etc/nginx /etc/nginx.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    fi

    # Remove any residual nginx files
    rm -rf /var/log/nginx.backup* 2>/dev/null || true
    rm -f /etc/logrotate.d/nginx.backup* 2>/dev/null || true

    # Clean package cache
    if command -v dnf >/dev/null 2>&1; then
        dnf clean all
    else
        yum clean all
    fi

    # Detect if it's Fedora or RHEL-based
    local repo_url
    if [[ -f /etc/fedora-release ]]; then
        repo_url="https://nginx.org/packages/fedora/\$releasever/\$basearch/"
        krun::install::nginx::log "INFO" "Detected Fedora system"
    else
        # Detect OS version for RHEL-based systems
        local os_version
        if [[ -f /etc/os-release ]]; then
            os_version=$(grep VERSION_ID /etc/os-release | cut -d'"' -f2 | cut -d'.' -f1)
        else
            os_version="7"
        fi
        repo_url="https://nginx.org/packages/centos/\$releasever/\$basearch/"
        krun::install::nginx::log "INFO" "Detected RHEL-based system (version: $os_version)"
    fi

    # Add official Nginx repository
    cat >/etc/yum.repos.d/nginx.repo <<EOF
[nginx-stable]
name=nginx stable repo
baseurl=${repo_url}
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=${repo_url/packages/packages\/mainline}
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF

    # Install nginx from official repository
    krun::install::nginx::log "INFO" "Installing nginx from nginx.org repository..."
    if command -v dnf >/dev/null 2>&1; then
        # Try normal install first, then with --allowerasing if there are conflicts
        if ! dnf install -y nginx 2>/dev/null; then
            krun::install::nginx::log "WARN" "Package conflicts detected, removing conflicting packages..."
            dnf remove -y nginx-core nginx-common 2>/dev/null || true
            dnf install -y --allowerasing nginx
        fi
    else
        # Try normal install first, then with conflict resolution
        if ! yum install -y nginx 2>/dev/null; then
            krun::install::nginx::log "WARN" "Package conflicts detected, removing conflicting packages..."
            yum remove -y nginx-core nginx-common 2>/dev/null || true
            yum install -y nginx --skip-broken || yum install -y nginx --nogpgcheck
        fi
    fi

    # Verify installation
    if ! command -v nginx >/dev/null 2>&1; then
        krun::install::nginx::error_exit "Failed to install nginx from official repository"
    fi

    INSTALL_TYPE="Official Nginx (nginx.org)"
    NGINX_VERSION=$(nginx -v 2>&1 | grep -o '[0-9.]*')

    krun::install::nginx::common
}

# mac code
krun::install::nginx::mac() {
    krun::install::nginx::log "INFO" "Installing Nginx on macOS..."

    # Install using Homebrew
    brew install nginx

    INSTALL_TYPE="Homebrew Nginx"
    NGINX_VERSION=$(nginx -v 2>&1 | grep -o '[0-9.]*')

    krun::install::nginx::common
}

# create nginx config
krun::install::nginx::create_nginx_config() {
    krun::install::nginx::log "INFO" "Creating optimized Nginx configuration..."

    local config_path="/etc/nginx"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        config_path="/usr/local/etc/nginx"
    fi

    # Backup original config
    if [[ -f "$config_path/nginx.conf" ]]; then
        cp "$config_path/nginx.conf" "$config_path/nginx.conf.bak.$(date +%Y%m%d_%H%M%S)"
        krun::install::nginx::log "INFO" "Original configuration backed up"
    fi

    # Create optimized nginx.conf
    cat >"$config_path/nginx.conf" <<'EOF'
# Nginx Configuration
# Optimized for performance and security

user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

# Load dynamic modules
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
    multi_accept on;
}

http {
    # Basic Settings
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Performance Settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 20M;
    client_body_timeout 12;
    client_header_timeout 12;
    send_timeout 10;

    # Security Settings
    server_tokens off;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Gzip Settings
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;

    # Rate Limiting
    limit_req_zone $binary_remote_addr zone=login:10m rate=10r/m;
    limit_req_zone $binary_remote_addr zone=api:10m rate=100r/m;

    # Include additional configurations
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

    # Adjust paths and settings for different platforms
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS specific adjustments
        sed -i '' 's|user nginx;|#user nginx;|g' "$config_path/nginx.conf"
        sed -i '' 's|/var/log/nginx/|/usr/local/var/log/nginx/|g' "$config_path/nginx.conf"
        sed -i '' 's|/var/run/nginx.pid|/usr/local/var/run/nginx.pid|g' "$config_path/nginx.conf"
        sed -i '' 's|/usr/share/nginx/modules/|/usr/local/share/nginx/modules/|g' "$config_path/nginx.conf"
        sed -i '' 's|/etc/nginx/|/usr/local/etc/nginx/|g' "$config_path/nginx.conf"
        sed -i '' 's|multi_accept on;|use kqueue;\n    multi_accept on;|g' "$config_path/nginx.conf"
    else
        # Linux specific adjustments
        sed -i 's|multi_accept on;|use epoll;\n    multi_accept on;|g' "$config_path/nginx.conf"
    fi

    krun::install::nginx::log "INFO" "Optimized nginx.conf created"
}

# create directories
krun::install::nginx::create_directories() {
    krun::install::nginx::log "INFO" "Creating directory structure..."

    local config_path="/etc/nginx"
    local log_path="/var/log/nginx"
    local www_path="/var/www"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        config_path="/usr/local/etc/nginx"
        log_path="/usr/local/var/log/nginx"
        www_path="/usr/local/var/www"
    fi

    # Create directories
    mkdir -p "$config_path/conf.d"
    mkdir -p "$config_path/sites-available"
    mkdir -p "$config_path/sites-enabled"
    mkdir -p "$config_path/ssl"
    mkdir -p "$log_path"
    mkdir -p "$www_path/html"

    # Set permissions (Linux only)
    if [[ "$OSTYPE" != "darwin"* ]]; then
        chown -R nginx:nginx "$www_path" 2>/dev/null || chown -R www-data:www-data "$www_path" 2>/dev/null || true
        chmod -R 755 "$www_path"
        chmod 700 "$config_path/ssl"
    fi

    krun::install::nginx::log "INFO" "Directory structure created"
}

# create default site
krun::install::nginx::create_default_site() {
    krun::install::nginx::log "INFO" "Creating default site configuration..."

    local config_path="/etc/nginx"
    local www_path="/var/www"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        config_path="/usr/local/etc/nginx"
        www_path="/usr/local/var/www"
    fi

    # Create default site config
    cat >"$config_path/sites-available/default" <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root $www_path/html;
    index index.html index.htm;

    server_name _;

    # Security headers
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Main location
    location / {
        try_files \$uri \$uri/ =404;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Deny access to backup files
    location ~ ~$ {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Static file caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|ttf|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Status page (optional)
    location = /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        allow ::1;
        deny all;
    }

    # Health check
    location = /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

    # Enable default site
    ln -sf "$config_path/sites-available/default" "$config_path/sites-enabled/default"

    # Create modern default index page
    cat >"$www_path/html/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to Nginx!</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            padding: 3rem;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 800px;
            width: 100%;
        }
        h1 {
            color: #667eea;
            margin-bottom: 1rem;
            font-size: 3rem;
            font-weight: 700;
        }
        .subtitle {
            color: #666;
            font-size: 1.2rem;
            margin-bottom: 2rem;
        }
        .status {
            background: linear-gradient(135deg, #d4edda, #c3e6cb);
            color: #155724;
            padding: 1.5rem;
            border-radius: 15px;
            margin: 2rem 0;
            border: 1px solid #c3e6cb;
            font-weight: 600;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 2rem;
            margin: 2rem 0;
        }
        .info-card {
            background: #f8f9fa;
            padding: 1.5rem;
            border-radius: 15px;
            text-align: left;
            border: 1px solid #e9ecef;
        }
        .info-card h3 {
            color: #495057;
            margin-bottom: 1rem;
            font-size: 1.3rem;
        }
        .info-card ul {
            list-style-type: none;
            padding: 0;
        }
        .info-card li {
            padding: 0.5rem 0;
            border-bottom: 1px solid #e9ecef;
        }
        .info-card li:last-child {
            border-bottom: none;
        }
        .version {
            font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
            background: #f1f3f4;
            padding: 0.3rem 0.8rem;
            border-radius: 8px;
            font-size: 0.9rem;
        }
        .links {
            margin-top: 2rem;
            padding-top: 2rem;
            border-top: 1px solid #e9ecef;
        }
        a {
            color: #667eea;
            text-decoration: none;
            font-weight: 600;
            margin: 0 1rem;
        }
        a:hover {
            text-decoration: underline;
        }
        .footer {
            margin-top: 2rem;
            color: #666;
            font-size: 0.9rem;
        }
        @media (max-width: 768px) {
            .container {
                padding: 2rem;
                margin: 10px;
            }
            h1 {
                font-size: 2rem;
            }
            .grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Welcome to Nginx!</h1>
        <p class="subtitle">High-performance web server is up and running</p>

        <div class="status">
            <strong>✅ Nginx is successfully installed and running!</strong>
        </div>

        <div class="grid">
            <div class="info-card">
                <h3>📋 Server Information</h3>
                <ul>
                    <li><strong>Server:</strong> <span class="version">nginx</span></li>
                    <li><strong>Installation:</strong> Configured by krun</li>
                    <li><strong>Document Root:</strong> <code>/var/www/html</code></li>
                    <li><strong>Configuration:</strong> <code>/etc/nginx/</code></li>
                </ul>
            </div>

            <div class="info-card">
                <h3>🔧 Management Commands</h3>
                <ul>
                    <li><code>systemctl start nginx</code></li>
                    <li><code>systemctl stop nginx</code></li>
                    <li><code>systemctl reload nginx</code></li>
                    <li><code>nginx -t</code> (test config)</li>
                </ul>
            </div>

            <div class="info-card">
                <h3>🎯 Next Steps</h3>
                <ul>
                    <li>Replace this default page</li>
                    <li>Configure virtual hosts</li>
                    <li>Enable SSL/TLS certificates</li>
                    <li>Set up monitoring</li>
                </ul>
            </div>

            <div class="info-card">
                <h3>🔒 Security Features</h3>
                <ul>
                    <li>Security headers enabled</li>
                    <li>Server tokens disabled</li>
                    <li>Rate limiting configured</li>
                    <li>Modern SSL/TLS settings</li>
                </ul>
            </div>
        </div>

        <div class="links">
            <a href="http://nginx.org/" target="_blank">Official Documentation</a>
            <a href="/nginx_status" target="_blank">Server Status</a>
            <a href="/health" target="_blank">Health Check</a>
        </div>

        <div class="footer">
            <p><em>Thank you for using nginx! Configured with ❤️ by krun</em></p>
        </div>
    </div>
</body>
</html>
EOF

    krun::install::nginx::log "INFO" "Default site created with modern design"
}

# configure firewall
krun::install::nginx::configure_firewall() {
    krun::install::nginx::log "INFO" "Configuring firewall..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        krun::install::nginx::log "INFO" "Skipping firewall configuration on macOS"
        return
    fi

    # Configure firewall based on available tools
    if command -v ufw >/dev/null 2>&1; then
        ufw --force enable
        ufw allow 80/tcp
        ufw allow 443/tcp
        krun::install::nginx::log "INFO" "UFW firewall configured"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --reload
        krun::install::nginx::log "INFO" "Firewalld configured"
    elif command -v iptables >/dev/null 2>&1; then
        iptables -A INPUT -p tcp --dport 80 -j ACCEPT
        iptables -A INPUT -p tcp --dport 443 -j ACCEPT
        # Save rules based on system
        if [[ -f /etc/debian_version ]]; then
            iptables-save >/etc/iptables/rules.v4 2>/dev/null || true
        elif [[ -f /etc/redhat-release ]]; then
            service iptables save 2>/dev/null || true
        fi
        krun::install::nginx::log "INFO" "iptables configured"
    else
        krun::install::nginx::log "WARN" "No supported firewall found"
    fi
}

# configure service
krun::install::nginx::configure_service() {
    krun::install::nginx::log "INFO" "Configuring Nginx service..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS service configuration
        krun::install::nginx::log "INFO" "To start nginx on macOS:"
        krun::install::nginx::log "INFO" "  Manual: sudo nginx"
        krun::install::nginx::log "INFO" "  Service: brew services start nginx"
        return
    fi

    # Linux service configuration
    systemctl enable nginx

    # Test configuration before starting
    if nginx -t; then
        systemctl start nginx

        # Verify service is running
        if systemctl is-active --quiet nginx; then
            krun::install::nginx::log "INFO" "Nginx service started successfully"
        else
            krun::install::nginx::error_exit "Failed to start Nginx service"
        fi
    else
        krun::install::nginx::error_exit "Nginx configuration test failed"
    fi
}

# test nginx
krun::install::nginx::test_nginx() {
    krun::install::nginx::log "INFO" "Testing Nginx installation..."

    # Test configuration syntax
    if nginx -t; then
        krun::install::nginx::log "INFO" "✅ Nginx configuration test passed"
    else
        krun::install::nginx::error_exit "❌ Nginx configuration test failed"
    fi

    # Test HTTP response (if service is running)
    if [[ "$OSTYPE" != "darwin"* ]]; then
        if systemctl is-active --quiet nginx; then
            sleep 2 # Give nginx a moment to fully start
            if curl -f -s http://localhost >/dev/null; then
                krun::install::nginx::log "INFO" "✅ HTTP response test passed"
            else
                krun::install::nginx::log "WARN" "⚠️ HTTP response test failed - check configuration"
            fi
        fi
    fi
}

# create helper scripts
krun::install::nginx::create_helper_scripts() {
    krun::install::nginx::log "INFO" "Creating helper scripts..."

    # Create nginx management script
    cat >/usr/local/bin/nginx-manage <<'EOF'
#!/bin/bash
# Nginx management helper script

case "$1" in
    "reload")
        sudo nginx -s reload
        echo "✓ Nginx reloaded"
        ;;
    "test")
        sudo nginx -t
        ;;
    "status")
        if command -v systemctl >/dev/null 2>&1; then
            systemctl status nginx
        else
            ps aux | grep nginx
        fi
        ;;
    "logs")
        if [[ -f /var/log/nginx/error.log ]]; then
            tail -f /var/log/nginx/error.log
        elif [[ -f /usr/local/var/log/nginx/error.log ]]; then
            tail -f /usr/local/var/log/nginx/error.log
        fi
        ;;
    "access")
        if [[ -f /var/log/nginx/access.log ]]; then
            tail -f /var/log/nginx/access.log
        elif [[ -f /usr/local/var/log/nginx/access.log ]]; then
            tail -f /usr/local/var/log/nginx/access.log
        fi
        ;;
    "configtest"|"t")
        sudo nginx -t
        ;;
    "version"|"v")
        nginx -v
        ;;
    *)
        echo "Nginx Management Helper"
        echo "Usage: nginx-manage {reload|test|status|logs|access|version}"
        echo ""
        echo "Commands:"
        echo "  reload  - Reload nginx configuration"
        echo "  test    - Test nginx configuration"
        echo "  status  - Show nginx service status"
        echo "  logs    - Show error logs (tail -f)"
        echo "  access  - Show access logs (tail -f)"
        echo "  version - Show nginx version"
        exit 1
        ;;
esac
EOF

    chmod +x /usr/local/bin/nginx-manage
    krun::install::nginx::log "INFO" "✅ nginx-manage helper script created"
}

# create security config
krun::install::nginx::create_security_config() {
    krun::install::nginx::log "INFO" "Creating additional security configurations..."

    local config_path="/etc/nginx"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        config_path="/usr/local/etc/nginx"
    fi

    # Create security config file
    cat >"$config_path/conf.d/security.conf" <<'EOF'
# Security configurations for Nginx

# Hide nginx version
server_tokens off;

# Prevent clickjacking
add_header X-Frame-Options DENY always;

# Prevent MIME type sniffing
add_header X-Content-Type-Options nosniff always;

# Enable XSS protection
add_header X-XSS-Protection "1; mode=block" always;

# Referrer policy
add_header Referrer-Policy "strict-origin-when-cross-origin" always;

# Content Security Policy
add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

# HSTS (uncomment when using HTTPS)
# add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

# Disable server signature
server_tokens off;

# Limit file upload size
client_max_body_size 20M;

# Buffer overflow protection
client_body_buffer_size 1K;
client_header_buffer_size 1k;
client_max_body_size 1k;
large_client_header_buffers 2 1k;

# Control timeouts
client_body_timeout 12;
client_header_timeout 12;
keepalive_timeout 15;
send_timeout 10;

# Control simultaneous connections
limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;
limit_req_zone $binary_remote_addr zone=req_limit_per_ip:10m rate=5r/s;
EOF

    krun::install::nginx::log "INFO" "✅ Security configuration created"
}

# common code
krun::install::nginx::common() {
    krun::install::nginx::log "INFO" "Executing common configuration tasks..."

    # Create all configurations
    krun::install::nginx::create_directories
    krun::install::nginx::create_nginx_config
    krun::install::nginx::create_default_site
    krun::install::nginx::create_security_config

    # Configure system
    krun::install::nginx::configure_firewall
    krun::install::nginx::configure_service

    # Test installation
    krun::install::nginx::test_nginx

    # Create helper tools
    krun::install::nginx::create_helper_scripts

    krun::install::nginx::log "INFO" "Common configuration completed"
}

# run code
krun::install::nginx::run() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "  🔥 Nginx Installation Script"
    echo "  📦 Installing latest Nginx version"
    echo "=========================================="
    echo -e "${NC}"

    krun::install::nginx::log "INFO" "Starting Nginx installation..."

    # detect platform
    local platform
    platform=$(krun::install::nginx::detect_platform)

    if [[ "$platform" == "unknown" ]]; then
        krun::install::nginx::error_exit "Unsupported platform detected"
    fi

    # Map platform names to function names
    case "$platform" in
    "rhel" | "fedora") platform="centos" ;;
    "macos") platform="mac" ;;
    esac

    krun::install::nginx::log "INFO" "Detected platform: $platform"

    # Check root privileges (except macOS)
    krun::install::nginx::check_root

    # Install dependencies
    krun::install::nginx::install_dependencies "$platform"

    # Install Nginx based on platform
    eval "${FUNCNAME/::run/::${platform}}"

    # Show success message
    krun::install::nginx::success_message

    krun::install::nginx::log "INFO" "Nginx installation completed successfully"
}

# run main
krun::install::nginx::run "$@"
