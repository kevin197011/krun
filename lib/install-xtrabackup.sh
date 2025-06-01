#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-xtrabackup.sh | bash

# vars
xtrabackup_version=${xtrabackup_version:-8.0}

# run code
krun::install::xtrabackup::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::xtrabackup::centos() {
    echo "Installing Percona XtraBackup on CentOS/RHEL..."

    # Install prerequisites
    yum install -y wget curl gnupg2

    # Install Percona repository
    echo "Adding Percona repository..."
    yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm

    # Enable the repository for the desired version
    if [[ "$xtrabackup_version" == "8.0" ]]; then
        percona-release enable-only pxb-80 release
        yum install -y percona-xtrabackup-80
    elif [[ "$xtrabackup_version" == "2.4" ]]; then
        percona-release enable-only pxb-24 release
        yum install -y percona-xtrabackup-24
    else
        echo "Installing latest XtraBackup..."
        percona-release enable-only pxb-80 release
        yum install -y percona-xtrabackup-80
    fi

    # Install additional utilities
    yum install -y qpress lz4 zstd

    krun::install::xtrabackup::common
}

# debian code
krun::install::xtrabackup::debian() {
    echo "Installing Percona XtraBackup on Debian/Ubuntu..."

    # Update package lists
    apt-get update

    # Install prerequisites
    apt-get install -y wget gnupg2 lsb-release curl

    # Download and install Percona repository package
    echo "Adding Percona repository..."
    wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
    dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
    rm -f percona-release_latest.$(lsb_release -sc)_all.deb

    # Update package lists
    apt-get update

    # Enable the repository for the desired version
    if [[ "$xtrabackup_version" == "8.0" ]]; then
        percona-release enable-only pxb-80 release
        apt-get update
        apt-get install -y percona-xtrabackup-80
    elif [[ "$xtrabackup_version" == "2.4" ]]; then
        percona-release enable-only pxb-24 release
        apt-get update
        apt-get install -y percona-xtrabackup-24
    else
        echo "Installing latest XtraBackup..."
        percona-release enable-only pxb-80 release
        apt-get update
        apt-get install -y percona-xtrabackup-80
    fi

    # Install additional utilities
    apt-get install -y qpress liblz4-tool zstd

    krun::install::xtrabackup::common
}

# mac code
krun::install::xtrabackup::mac() {
    echo "Installing Percona XtraBackup on macOS..."

    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew is required for XtraBackup installation on macOS"
        return 1
    fi

    # Install XtraBackup via Homebrew
    brew install percona-xtrabackup

    # Install additional utilities
    brew install qpress lz4 zstd

    krun::install::xtrabackup::common
}

# common code
krun::install::xtrabackup::common() {
    echo "Configuring Percona XtraBackup..."

    # Verify installation
    krun::install::xtrabackup::verify_installation

    # Configure backup directories
    krun::install::xtrabackup::setup_directories

    # Create example scripts
    krun::install::xtrabackup::create_scripts

    echo ""
    echo "=== Percona XtraBackup Installation Summary ==="
    echo "Version: $(xtrabackup --version 2>&1 | head -1 || echo 'Unknown')"
    echo "Executable: $(which xtrabackup 2>/dev/null || echo 'Not found')"
    echo "Backup directory: /var/backups/mysql"
    echo "Script directory: /usr/local/bin"
    echo ""
    echo "Common XtraBackup commands:"
    echo "  xtrabackup --backup --target-dir=/path/to/backup"
    echo "  xtrabackup --prepare --target-dir=/path/to/backup"
    echo "  xtrabackup --copy-back --target-dir=/path/to/backup"
    echo ""
    echo "Example backup scripts created:"
    echo "  /usr/local/bin/mysql-backup.sh     - Full backup script"
    echo "  /usr/local/bin/mysql-restore.sh    - Restore script"
    echo ""
    echo "Documentation: https://docs.percona.com/percona-xtrabackup/"
    echo ""
    echo "Percona XtraBackup is ready to use!"
}

# Verify XtraBackup installation
krun::install::xtrabackup::verify_installation() {
    echo "Verifying XtraBackup installation..."

    # Check xtrabackup command
    if command -v xtrabackup >/dev/null 2>&1; then
        echo "✓ xtrabackup command is available"
        xtrabackup --version
    else
        echo "✗ xtrabackup command not found"
        return 1
    fi

    # Check for additional tools
    if command -v xbstream >/dev/null 2>&1; then
        echo "✓ xbstream is available"
    fi

    if command -v xbcrypt >/dev/null 2>&1; then
        echo "✓ xbcrypt is available"
    fi

    if command -v qpress >/dev/null 2>&1; then
        echo "✓ qpress compression tool is available"
    else
        echo "⚠ qpress not found (optional compression tool)"
    fi

    echo "✓ XtraBackup installation verified"
}

# Setup backup directories
krun::install::xtrabackup::setup_directories() {
    echo "Setting up backup directories..."

    local backup_dir="/var/backups/mysql"
    local log_dir="/var/log/mysql-backup"

    # Create backup directory
    mkdir -p "$backup_dir"
    chmod 750 "$backup_dir"

    # Create log directory
    mkdir -p "$log_dir"
    chmod 750 "$log_dir"

    # Set ownership (if mysql user exists)
    if id mysql >/dev/null 2>&1; then
        chown mysql:mysql "$backup_dir" "$log_dir" 2>/dev/null || true
    fi

    echo "✓ Backup directories created:"
    echo "  Backups: $backup_dir"
    echo "  Logs: $log_dir"
}

# Create example backup scripts
krun::install::xtrabackup::create_scripts() {
    echo "Creating example backup scripts..."

    # Create backup script
    cat >/usr/local/bin/mysql-backup.sh <<'EOF'
#!/usr/bin/env bash
# MySQL Backup Script using Percona XtraBackup

set -o errexit
set -o nounset
set -o pipefail

# Configuration
BACKUP_DIR="/var/backups/mysql"
LOG_DIR="/var/log/mysql-backup"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup_$DATE"
LOG_FILE="$LOG_DIR/backup_$DATE.log"

# MySQL connection parameters (adjust as needed)
MYSQL_USER="root"
MYSQL_PASSWORD=""
MYSQL_HOST="localhost"
MYSQL_PORT="3306"

# Retention (days)
RETENTION_DAYS=7

# Create directories
mkdir -p "$BACKUP_DIR" "$LOG_DIR"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to cleanup old backups
cleanup_old_backups() {
    log "Cleaning up backups older than $RETENTION_DAYS days..."
    find "$BACKUP_DIR" -name "backup_*" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null || true
    find "$LOG_DIR" -name "backup_*.log" -type f -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
}

# Main backup function
perform_backup() {
    log "Starting MySQL backup to $BACKUP_PATH"

    # Build xtrabackup command
    local xtrabackup_cmd="xtrabackup --backup"
    xtrabackup_cmd="$xtrabackup_cmd --target-dir=$BACKUP_PATH"
    xtrabackup_cmd="$xtrabackup_cmd --host=$MYSQL_HOST"
    xtrabackup_cmd="$xtrabackup_cmd --port=$MYSQL_PORT"
    xtrabackup_cmd="$xtrabackup_cmd --user=$MYSQL_USER"

    if [[ -n "$MYSQL_PASSWORD" ]]; then
        xtrabackup_cmd="$xtrabackup_cmd --password=$MYSQL_PASSWORD"
    fi

    # Perform backup
    if $xtrabackup_cmd 2>>"$LOG_FILE"; then
        log "Backup completed successfully"

        # Prepare backup
        log "Preparing backup..."
        if xtrabackup --prepare --target-dir="$BACKUP_PATH" 2>>"$LOG_FILE"; then
            log "Backup preparation completed"

            # Create info file
            echo "Backup Date: $(date)" > "$BACKUP_PATH/backup_info.txt"
            echo "MySQL Host: $MYSQL_HOST:$MYSQL_PORT" >> "$BACKUP_PATH/backup_info.txt"
            echo "Backup Path: $BACKUP_PATH" >> "$BACKUP_PATH/backup_info.txt"

            log "Backup info created"
        else
            log "ERROR: Backup preparation failed"
            return 1
        fi
    else
        log "ERROR: Backup failed"
        return 1
    fi
}

# Main execution
log "=== MySQL Backup Started ==="
perform_backup
cleanup_old_backups
log "=== MySQL Backup Completed ==="

EOF

    # Create restore script
    cat >/usr/local/bin/mysql-restore.sh <<'EOF'
#!/usr/bin/env bash
# MySQL Restore Script using Percona XtraBackup

set -o errexit
set -o nounset
set -o pipefail

# Configuration
BACKUP_DIR="/var/backups/mysql"
LOG_DIR="/var/log/mysql-backup"
MYSQL_DATADIR="/var/lib/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/restore_$DATE.log"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to show usage
usage() {
    echo "Usage: $0 <backup_directory>"
    echo "Example: $0 /var/backups/mysql/backup_20231201_120000"
    exit 1
}

# Function to stop MySQL service
stop_mysql() {
    log "Stopping MySQL service..."
    if command -v systemctl >/dev/null 2>&1; then
        systemctl stop mysql || systemctl stop mysqld || true
    elif command -v service >/dev/null 2>&1; then
        service mysql stop || service mysqld stop || true
    else
        log "Please stop MySQL service manually"
        read -p "Press Enter when MySQL is stopped..."
    fi
}

# Function to start MySQL service
start_mysql() {
    log "Starting MySQL service..."
    if command -v systemctl >/dev/null 2>&1; then
        systemctl start mysql || systemctl start mysqld || true
    elif command -v service >/dev/null 2>&1; then
        service mysql start || service mysqld start || true
    else
        log "Please start MySQL service manually"
    fi
}

# Main restore function
perform_restore() {
    local backup_path="$1"

    log "Starting MySQL restore from $backup_path"

    # Verify backup directory
    if [[ ! -d "$backup_path" ]]; then
        log "ERROR: Backup directory not found: $backup_path"
        return 1
    fi

    # Check if backup is prepared
    if [[ ! -f "$backup_path/xtrabackup_checkpoints" ]]; then
        log "ERROR: Backup appears to be incomplete or not prepared"
        return 1
    fi

    # Backup current data directory
    if [[ -d "$MYSQL_DATADIR" ]]; then
        local backup_current="$MYSQL_DATADIR.backup_$DATE"
        log "Backing up current data directory to $backup_current"
        mv "$MYSQL_DATADIR" "$backup_current"
    fi

    # Create new data directory
    mkdir -p "$MYSQL_DATADIR"

    # Restore backup
    log "Restoring backup..."
    if xtrabackup --copy-back --target-dir="$backup_path" --datadir="$MYSQL_DATADIR" 2>>"$LOG_FILE"; then
        log "Restore completed successfully"

        # Fix permissions
        chown -R mysql:mysql "$MYSQL_DATADIR" 2>/dev/null || true

        log "Permissions fixed"
    else
        log "ERROR: Restore failed"
        return 1
    fi
}

# Check arguments
if [[ $# -ne 1 ]]; then
    usage
fi

BACKUP_PATH="$1"

# Create log directory
mkdir -p "$LOG_DIR"

# Main execution
log "=== MySQL Restore Started ==="
log "Backup source: $BACKUP_PATH"
log "Data directory: $MYSQL_DATADIR"

echo "WARNING: This will replace your current MySQL data!"
echo "Backup source: $BACKUP_PATH"
echo "Data directory: $MYSQL_DATADIR"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
    log "Restore cancelled by user"
    exit 0
fi

stop_mysql
perform_restore "$BACKUP_PATH"
start_mysql

log "=== MySQL Restore Completed ==="
log "Please verify your database integrity"

EOF

    # Make scripts executable
    chmod +x /usr/local/bin/mysql-backup.sh
    chmod +x /usr/local/bin/mysql-restore.sh

    echo "✓ Example scripts created:"
    echo "  /usr/local/bin/mysql-backup.sh"
    echo "  /usr/local/bin/mysql-restore.sh"
}

# run main
krun::install::xtrabackup::run "$@"
