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

# run code
krun::install::nginx::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::nginx::centos() {
    echo "Installing Nginx/OpenResty on CentOS/RHEL..."

    # Install EPEL repository
    yum install -y epel-release

    # Try OpenResty first, fallback to nginx
    echo "Attempting to install OpenResty..."
    if ! krun::install::nginx::install_openresty_centos; then
        echo "OpenResty installation failed, installing nginx from EPEL..."
        yum install -y nginx
    fi

    krun::install::nginx::common
}

# debian code
krun::install::nginx::debian() {
    echo "Installing Nginx/OpenResty on Debian/Ubuntu..."

    # Update package lists
    apt-get update

    # Try OpenResty first, fallback to nginx
    echo "Attempting to install OpenResty..."
    if ! krun::install::nginx::install_openresty_debian; then
        echo "OpenResty installation failed, installing nginx from repository..."
        apt-get install -y nginx
    fi

    krun::install::nginx::common
}

# mac code
krun::install::nginx::mac() {
    echo "Installing Nginx/OpenResty on macOS..."

    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew is required for macOS installation"
        exit 1
    fi

    # Try OpenResty first, fallback to nginx
    echo "Attempting to install OpenResty..."
    if ! krun::install::nginx::install_openresty_mac; then
        echo "OpenResty installation failed, installing nginx..."
        brew install nginx
    fi

    krun::install::nginx::common
}

# Install OpenResty on CentOS
krun::install::nginx::install_openresty_centos() {
    # Add OpenResty repository
    yum install -y yum-utils
    yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo

    # Install OpenResty
    yum install -y openresty openresty-resty

    # Create symlink for nginx command
    ln -sf /usr/local/openresty/bin/openresty /usr/local/bin/nginx
    ln -sf /usr/local/openresty/nginx/sbin/nginx /usr/local/bin/nginx

    return 0
}

# Install OpenResty on Debian/Ubuntu
krun::install::nginx::install_openresty_debian() {
    # Add OpenResty repository
    apt-get install -y software-properties-common curl

    # Import GPG key
    curl -fsSL https://openresty.org/package/pubkey.gpg | apt-key add -

    # Add repository
    local codename
    codename=$(lsb_release -sc)
    add-apt-repository -y "deb http://openresty.org/package/ubuntu ${codename} main"

    # Update and install
    apt-get update
    apt-get install -y openresty

    # Create symlink for nginx command
    ln -sf /usr/local/openresty/bin/openresty /usr/local/bin/nginx
    ln -sf /usr/local/openresty/nginx/sbin/nginx /usr/local/bin/nginx

    return 0
}

# Install OpenResty on macOS
krun::install::nginx::install_openresty_mac() {
    # Add OpenResty tap
    brew tap openresty/brew

    # Install OpenResty
    brew install openresty/brew/openresty

    return 0
}

# common code
krun::install::nginx::common() {
    echo "Configuring Nginx/OpenResty..."

    # Detect which nginx is installed
    local nginx_bin=""
    local nginx_type=""

    if command -v openresty >/dev/null 2>&1; then
        nginx_bin="openresty"
        nginx_type="OpenResty"
    elif command -v nginx >/dev/null 2>&1; then
        nginx_bin="nginx"
        nginx_type="Nginx"
    else
        echo "Neither nginx nor openresty command found"
        return 1
    fi

    echo "✓ ${nginx_type} installed successfully"

    # Show version
    ${nginx_bin} -v

    # Test configuration
    echo "Testing configuration..."
    ${nginx_bin} -t || echo "⚠ Configuration test failed"

    # Configure and start service
    krun::install::nginx::configure_service

    # Create basic configuration
    krun::install::nginx::create_basic_config

    echo ""
    echo "=== Nginx/OpenResty Installation Summary ==="
    echo "Type: ${nginx_type}"
    echo "Binary: ${nginx_bin}"
    echo "Configuration test: $(${nginx_bin} -t 2>&1 | grep -q 'successful' && echo 'PASSED' || echo 'FAILED')"

    # Show service status
    if command -v systemctl >/dev/null 2>&1; then
        echo "Service status: $(systemctl is-active nginx 2>/dev/null || echo 'inactive')"
    fi

    echo ""
    echo "Quick commands:"
    echo "  Start:   systemctl start nginx"
    echo "  Stop:    systemctl stop nginx"
    echo "  Reload:  systemctl reload nginx"
    echo "  Status:  systemctl status nginx"
    echo "  Test:    nginx -t"
}

# Configure nginx service
krun::install::nginx::configure_service() {
    echo "Configuring nginx service..."

    if command -v systemctl >/dev/null 2>&1; then
        # Linux with systemd
        if [[ ! -f /etc/systemd/system/nginx.service ]] && [[ ! -f /usr/lib/systemd/system/nginx.service ]]; then
            # Create systemd service file if not exists
            cat >/etc/systemd/system/nginx.service <<EOF
[Unit]
Description=nginx - high performance web server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx.conf
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s TERM \$MAINPID

[Install]
WantedBy=multi-user.target
EOF
            systemctl daemon-reload
        fi

        # Enable and start service
        systemctl enable nginx
        systemctl start nginx || echo "⚠ Failed to start nginx service"

    elif [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        if [[ -f /usr/local/etc/nginx/nginx.conf ]]; then
            echo "✓ Nginx configured for macOS"
            echo "To start nginx: brew services start nginx"
        fi
    else
        echo "⚠ Unable to configure service on this system"
    fi
}

# Create basic nginx configuration
krun::install::nginx::create_basic_config() {
    local config_dir="/etc/nginx"

    # Detect config directory
    if [[ -d /usr/local/openresty/nginx/conf ]]; then
        config_dir="/usr/local/openresty/nginx/conf"
    elif [[ -d /usr/local/etc/nginx ]]; then
        config_dir="/usr/local/etc/nginx"
    elif [[ -d /etc/nginx ]]; then
        config_dir="/etc/nginx"
    fi

    echo "Using config directory: ${config_dir}"

    # Create directories
    mkdir -p "${config_dir}/conf.d"
    mkdir -p "${config_dir}/sites-available"
    mkdir -p "${config_dir}/sites-enabled"

    # Create a basic default site if not exists
    if [[ ! -f "${config_dir}/sites-available/default" ]]; then
        cat >"${config_dir}/sites-available/default" <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

        # Enable default site
        ln -sf "${config_dir}/sites-available/default" "${config_dir}/sites-enabled/default" 2>/dev/null || true
    fi

    # Create web root
    mkdir -p /var/www/html

    # Create default index page if not exists
    if [[ ! -f /var/www/html/index.html ]]; then
        cat >/var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to nginx!</title>
</head>
<body>
    <h1>Welcome to nginx!</h1>
    <p>If you see this page, the nginx web server is successfully installed and working.</p>
    <p>For online documentation and support please refer to <a href="http://nginx.org/">nginx.org</a>.</p>
    <p><em>Thank you for using nginx.</em></p>
</body>
</html>
EOF
    fi

    echo "✓ Basic configuration created"
}

# run main
krun::install::nginx::run "$@"
