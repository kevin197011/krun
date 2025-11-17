#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-redis.sh | bash

# vars
redis_version=${redis_version:-7.2.4}

# run code
krun::install::redis::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::redis::centos() {
    echo "Installing Redis on CentOS/RHEL..."

    # Install EPEL repository
    yum install -y epel-release

    # Install Redis from repository
    yum install -y redis

    krun::install::redis::common
}

# debian code
krun::install::redis::debian() {
    echo "Installing Redis on Debian/Ubuntu..."

    # Update package lists
    apt-get update

    # Install Redis from repository
    apt-get install -y redis-server redis-tools

    krun::install::redis::common
}

# mac code
krun::install::redis::mac() {
    echo "Installing Redis on macOS..."

    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew is required for Redis installation on macOS"
        return 1
    fi

    # Install Redis via Homebrew
    brew install redis

    krun::install::redis::common
}

# common code
krun::install::redis::common() {
    echo "Configuring Redis..."

    # Verify Redis installation
    if ! command -v redis-server >/dev/null 2>&1; then
        echo "✗ Redis server not found, trying manual installation..."
        krun::install::redis::manual_install
        return
    fi

    echo "✓ Redis installed successfully"
    redis-server --version

    # Configure Redis
    krun::install::redis::configure_redis

    # Start and enable Redis service
    krun::install::redis::manage_service

    # Test Redis
    krun::install::redis::test_redis

    echo ""
    echo "=== Redis Installation Summary ==="
    echo "Version: $(redis-server --version | head -1)"
    echo "Configuration: /etc/redis/redis.conf (or /usr/local/etc/redis.conf on macOS)"
    echo "Service status: $(systemctl is-active redis 2>/dev/null || echo 'unknown')"
    echo ""
    echo "Common Redis commands:"
    echo "  redis-cli           - Connect to Redis CLI"
    echo "  redis-cli ping      - Test connection"
    echo "  redis-cli info      - Show server info"
    echo "  redis-cli shutdown  - Shutdown Redis"
    echo ""
    echo "Service management:"
    echo "  systemctl start redis    - Start Redis"
    echo "  systemctl stop redis     - Stop Redis"
    echo "  systemctl restart redis  - Restart Redis"
    echo "  systemctl status redis   - Check status"
    echo ""
    echo "Redis is ready to use!"
}

# Manual Redis installation
krun::install::redis::manual_install() {
    echo "Installing Redis ${redis_version} manually..."

    # Install build dependencies
    if command -v yum >/dev/null 2>&1; then
        yum groupinstall -y "Development Tools" || yum install -y gcc make
        yum install -y tcl
    elif command -v apt-get >/dev/null 2>&1; then
        apt-get install -y build-essential tcl
    fi

    # Download and compile Redis
    cd /tmp
    curl -L -o redis.tar.gz "http://download.redis.io/releases/redis-${redis_version}.tar.gz"
    tar -xzf redis.tar.gz
    cd redis-${redis_version}

    # Compile
    make
    make test || echo "⚠ Tests failed, continuing installation..."
    make install

    # Create Redis user
    useradd -r -s /bin/false redis || true

    # Create directories
    mkdir -p /etc/redis /var/lib/redis /var/log/redis
    chown redis:redis /var/lib/redis /var/log/redis

    # Copy configuration
    cp redis.conf /etc/redis/redis.conf

    # Clean up
    cd /
    rm -rf /tmp/redis.tar.gz /tmp/redis-${redis_version}

    echo "✓ Redis installed manually"
}

# Configure Redis
krun::install::redis::configure_redis() {
    echo "Configuring Redis..."

    local config_file=""
    local redis_user="redis"

    # Find Redis configuration file
    if [[ -f /etc/redis/redis.conf ]]; then
        config_file="/etc/redis/redis.conf"
    elif [[ -f /etc/redis.conf ]]; then
        config_file="/etc/redis.conf"
    elif [[ -f /usr/local/etc/redis.conf ]]; then
        config_file="/usr/local/etc/redis.conf"
        redis_user="$(whoami)" # On macOS, use current user
    else
        echo "⚠ Redis configuration file not found"
        return
    fi

    # Backup original configuration
    if [[ ! -f "${config_file}.bak" ]]; then
        cp "$config_file" "${config_file}.bak"
        echo "✓ Backed up Redis configuration"
    fi

    # Apply basic security configurations
    sed -i.tmp 's/^# bind 127.0.0.1/bind 127.0.0.1/' "$config_file" 2>/dev/null || true
    sed -i.tmp 's/^bind 127.0.0.1 ::1/bind 127.0.0.1/' "$config_file" 2>/dev/null || true

    # Set password (optional)
    # sed -i.tmp 's/^# requirepass foobared/requirepass your_secure_password/' "$config_file"

    # Configure as daemon
    sed -i.tmp 's/^daemonize no/daemonize yes/' "$config_file" 2>/dev/null || true

    # Set log file
    if [[ "$config_file" != "/usr/local/etc/redis.conf" ]]; then
        sed -i.tmp 's|^logfile ""|logfile /var/log/redis/redis.log|' "$config_file" 2>/dev/null || true
        sed -i.tmp 's|^dir ./|dir /var/lib/redis|' "$config_file" 2>/dev/null || true
    fi

    # Clean up temp files
    rm -f "${config_file}.tmp"

    echo "✓ Redis configuration updated"
}

# Manage Redis service
krun::install::redis::manage_service() {
    echo "Managing Redis service..."

    if command -v systemctl >/dev/null 2>&1; then
        # Linux with systemd
        local service_name="redis"

        # Try different service names
        if systemctl list-unit-files | grep -q "redis-server.service"; then
            service_name="redis-server"
        elif systemctl list-unit-files | grep -q "redis.service"; then
            service_name="redis"
        fi

        # Enable and start service
        systemctl enable "$service_name" 2>/dev/null || true
        systemctl start "$service_name" 2>/dev/null || echo "⚠ Failed to start Redis service"

        # Check status
        if systemctl is-active "$service_name" >/dev/null 2>&1; then
            echo "✓ Redis service is running"
        else
            echo "⚠ Redis service is not running"
        fi

    elif [[ "$(uname)" == "Darwin" ]]; then
        # macOS with Homebrew
        if command -v brew >/dev/null 2>&1; then
            brew services start redis || echo "⚠ Failed to start Redis with brew services"
            echo "✓ Redis service configured for macOS"
        fi
    else
        echo "⚠ Cannot manage Redis service on this system"
    fi
}

# Test Redis installation
krun::install::redis::test_redis() {
    echo "Testing Redis installation..."

    # Wait a moment for Redis to start
    sleep 2

    # Test Redis connection
    if command -v redis-cli >/dev/null 2>&1; then
        if redis-cli ping 2>/dev/null | grep -q "PONG"; then
            echo "✓ Redis is responding to ping"

            # Test basic operations
            redis-cli set test_key "Hello Redis" >/dev/null 2>&1
            local test_value=$(redis-cli get test_key 2>/dev/null)
            if [[ "$test_value" == "Hello Redis" ]]; then
                echo "✓ Redis read/write operations working"
                redis-cli del test_key >/dev/null 2>&1
            else
                echo "✗ Redis read/write test failed"
            fi
        else
            echo "✗ Redis is not responding"
        fi
    else
        echo "✗ redis-cli not found"
    fi
}

# run main
krun::install::redis::run "$@"
