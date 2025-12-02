#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-nginx.sh | bash

# vars

# run code
krun::install::nginx::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::nginx::centos() {
    echo "Installing Nginx on RHEL/CentOS/Rocky/AlmaLinux/Fedora..."

    [[ "$OSTYPE" != "darwin"* ]] && [[ $EUID -ne 0 ]] && echo "✗ Please run as root" && return 1

    if command -v dnf >/dev/null 2>&1; then
        dnf remove -y nginx nginx-core nginx-common nginx-module-* 2>/dev/null || true
        dnf install -y curl wget gnupg2 yum-utils ca-certificates
    else
        yum remove -y nginx nginx-core nginx-common nginx-module-* 2>/dev/null || true
        yum install -y curl wget gnupg2 yum-utils ca-certificates
    fi

    systemctl stop nginx 2>/dev/null || true
    systemctl disable nginx 2>/dev/null || true

    if [[ -d /etc/nginx ]]; then
        mv /etc/nginx /etc/nginx.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    fi

    local repo_url="https://nginx.org/packages/centos/\$releasever/\$basearch/"
    [[ -f /etc/fedora-release ]] && repo_url="https://nginx.org/packages/fedora/\$releasever/\$basearch/"

    cat >/etc/yum.repos.d/nginx.repo <<EOF
[nginx-stable]
name=nginx stable repo
baseurl=${repo_url}
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF

    if command -v dnf >/dev/null 2>&1; then
        if ! dnf install -y nginx 2>/dev/null; then
            dnf remove -y nginx-core nginx-common 2>/dev/null || true
            dnf install -y --allowerasing nginx
        fi
    else
        if ! yum install -y nginx 2>/dev/null; then
            yum remove -y nginx-core nginx-common 2>/dev/null || true
            yum install -y nginx --skip-broken || yum install -y nginx --nogpgcheck
        fi
    fi

    command -v nginx >/dev/null || {
        echo "✗ Failed to install nginx"
        return 1
    }

    krun::install::nginx::common
}

# debian code
krun::install::nginx::debian() {
    echo "Installing Nginx on Debian/Ubuntu..."

    [[ "$OSTYPE" != "darwin"* ]] && [[ $EUID -ne 0 ]] && echo "✗ Please run as root" && return 1

    apt-get update -qq
    apt-get install -y curl wget gnupg2 software-properties-common lsb-release ca-certificates

    curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

    local codename=$(lsb_release -cs)
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu $codename nginx" >/etc/apt/sources.list.d/nginx.list

    cat >/etc/apt/preferences.d/99nginx <<EOF
Package: *
Pin: origin nginx.org
Pin: release o=nginx
Pin-Priority: 900
EOF

    apt-get update -qq
    apt-get install -y nginx

    krun::install::nginx::common
}

# mac code
krun::install::nginx::mac() {
    echo "Installing Nginx on macOS..."

    command -v brew >/dev/null || {
        echo "✗ Homebrew is required for macOS installation"
        return 1
    }

    brew install nginx

    krun::install::nginx::common
}

# create nginx config
krun::install::nginx::create_config() {
    local config_path="/etc/nginx"
    [[ "$OSTYPE" == "darwin"* ]] && config_path="/usr/local/etc/nginx"

    [[ -f "$config_path/nginx.conf" ]] && cp "$config_path/nginx.conf" "$config_path/nginx.conf.bak.$(date +%Y%m%d_%H%M%S)"

    cat >"$config_path/nginx.conf" <<'EOF'
# Nginx Configuration
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 20M;
    client_body_timeout 12;
    client_header_timeout 12;
    send_timeout 10;

    server_tokens off;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's|user nginx;|#user nginx;|g' "$config_path/nginx.conf"
        sed -i '' 's|/var/log/nginx/|/usr/local/var/log/nginx/|g' "$config_path/nginx.conf"
        sed -i '' 's|/var/run/nginx.pid|/usr/local/var/run/nginx.pid|g' "$config_path/nginx.conf"
        sed -i '' 's|/usr/share/nginx/modules/|/usr/local/share/nginx/modules/|g' "$config_path/nginx.conf"
        sed -i '' 's|/etc/nginx/|/usr/local/etc/nginx/|g' "$config_path/nginx.conf"
        sed -i '' 's|multi_accept on;|use kqueue;\n    multi_accept on;|g' "$config_path/nginx.conf"
    else
        sed -i 's|multi_accept on;|use epoll;\n    multi_accept on;|g' "$config_path/nginx.conf"
    fi
}

# create directories
krun::install::nginx::create_directories() {
    local config_path="/etc/nginx"
    local log_path="/var/log/nginx"
    local www_path="/var/www"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        config_path="/usr/local/etc/nginx"
        log_path="/usr/local/var/log/nginx"
        www_path="/usr/local/var/www"
    fi

    mkdir -p "$config_path/conf.d"
    mkdir -p "$config_path/sites-available"
    mkdir -p "$config_path/sites-enabled"
    mkdir -p "$config_path/ssl"
    mkdir -p "$log_path"
    mkdir -p "$www_path/html"

    if [[ "$OSTYPE" != "darwin"* ]]; then
        chown -R nginx:nginx "$www_path" 2>/dev/null || chown -R www-data:www-data "$www_path" 2>/dev/null || true
        chmod -R 755 "$www_path"
        chmod 700 "$config_path/ssl"
    fi
}

# create default site
krun::install::nginx::create_default_site() {
    local config_path="/etc/nginx"
    local www_path="/var/www"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        config_path="/usr/local/etc/nginx"
        www_path="/usr/local/var/www"
    fi

    cat >"$config_path/sites-available/default" <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root $www_path/html;
    index index.html index.htm;

    server_name _;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~ ~$ {
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff|woff2|ttf|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    location = /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        allow ::1;
        deny all;
    }

    location = /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

    ln -sf "$config_path/sites-available/default" "$config_path/sites-enabled/default"

    cat >"$www_path/html/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to Nginx!</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
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
        h1 { color: #667eea; margin-bottom: 1rem; font-size: 3rem; font-weight: 700; }
        .subtitle { color: #666; font-size: 1.2rem; margin-bottom: 2rem; }
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
        .info-card h3 { color: #495057; margin-bottom: 1rem; font-size: 1.3rem; }
        .info-card ul { list-style-type: none; padding: 0; }
        .info-card li { padding: 0.5rem 0; border-bottom: 1px solid #e9ecef; }
        .info-card li:last-child { border-bottom: none; }
        .version {
            font-family: 'SF Mono', Monaco, monospace;
            background: #f1f3f4;
            padding: 0.3rem 0.8rem;
            border-radius: 8px;
            font-size: 0.9rem;
        }
        .links { margin-top: 2rem; padding-top: 2rem; border-top: 1px solid #e9ecef; }
        a { color: #667eea; text-decoration: none; font-weight: 600; margin: 0 1rem; }
        a:hover { text-decoration: underline; }
        .footer { margin-top: 2rem; color: #666; font-size: 0.9rem; }
        @media (max-width: 768px) {
            .container { padding: 2rem; margin: 10px; }
            h1 { font-size: 2rem; }
            .grid { grid-template-columns: 1fr; }
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
                    <li><code>systemctl restart nginx</code></li>
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
}

# configure service
krun::install::nginx::configure_service() {
    [[ "$OSTYPE" == "darwin"* ]] && {
        echo "To start nginx on macOS: sudo nginx or brew services start nginx"
        return
    }

    systemctl enable nginx

    nginx -t || {
        echo "✗ Nginx configuration test failed"
        return 1
    }

    systemctl restart nginx
    systemctl is-active --quiet nginx || {
        echo "✗ Failed to restart Nginx service"
        return 1
    }
}

# create security config
krun::install::nginx::create_security_config() {
    local config_path="/etc/nginx"
    [[ "$OSTYPE" == "darwin"* ]] && config_path="/usr/local/etc/nginx"

    [[ -f "$config_path/conf.d/security.conf" ]] && mv "$config_path/conf.d/security.conf" "$config_path/conf.d/security.conf.bak.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || rm -f "$config_path/conf.d/security.conf"

    cat >"$config_path/conf.d/security.conf" <<'EOF'
# Security configurations for Nginx
add_header X-Frame-Options DENY always;
add_header X-Content-Type-Options nosniff always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;
limit_req_zone $binary_remote_addr zone=req_limit_per_ip:10m rate=5r/s;
EOF
}

# create helper scripts
krun::install::nginx::create_helper_scripts() {
    cat >/usr/local/bin/nginx-manage <<'EOF'
#!/bin/bash
case "$1" in
    "reload")
        sudo nginx -s reload
        echo "✓ Nginx reloaded"
        ;;
    "test")
        sudo nginx -t
        ;;
    "status")
        command -v systemctl >/dev/null 2>&1 && systemctl status nginx || ps aux | grep nginx
        ;;
    "logs")
        [[ -f /var/log/nginx/error.log ]] && tail -f /var/log/nginx/error.log || tail -f /usr/local/var/log/nginx/error.log
        ;;
    "access")
        [[ -f /var/log/nginx/access.log ]] && tail -f /var/log/nginx/access.log || tail -f /usr/local/var/log/nginx/access.log
        ;;
    "configtest"|"t")
        sudo nginx -t
        ;;
    "version"|"v")
        nginx -v
        ;;
    *)
        echo "Usage: nginx-manage {reload|test|status|logs|access|version}"
        exit 1
        ;;
esac
EOF
    chmod +x /usr/local/bin/nginx-manage
}

# common code
krun::install::nginx::common() {
    echo "Configuring Nginx..."

    krun::install::nginx::create_directories
    krun::install::nginx::create_config
    krun::install::nginx::create_default_site
    krun::install::nginx::create_security_config
    krun::install::nginx::configure_service
    krun::install::nginx::create_helper_scripts

    nginx -t && echo "✓ Nginx configuration test passed" || echo "⚠ Nginx configuration test failed"

    if [[ "$OSTYPE" != "darwin"* ]] && systemctl is-active --quiet nginx; then
        sleep 2
        curl -f -s http://localhost >/dev/null && echo "✓ HTTP response test passed" || echo "⚠ HTTP response test failed"
    fi

    echo ""
    echo "✓ Nginx installation completed"
    echo "Version: $(nginx -v 2>&1 | grep -o '[0-9.]*')"
    echo ""
    echo "Quick Commands:"
    echo "  systemctl restart nginx"
    echo "  systemctl stop nginx"
    echo "  systemctl reload nginx"
    echo "  nginx -t"
    echo ""
    echo "Default site: http://localhost"
    echo "Helper script: nginx-manage {reload|test|status|logs|access}"
}

# run main
krun::install::nginx::run "$@"
