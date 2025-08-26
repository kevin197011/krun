#!/usr/bin/env bash

# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-rocky-repo.sh | bash

# vars
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# run code
krun::config::rocky-repo::run() {
    echo -e "${BLUE}🔧 Configuring Rocky Linux repositories for IPv4...${NC}"

    # detect platform with better logic
    platform='debian'
    if command -v dnf >/dev/null 2>&1; then
        platform='centos'
    elif command -v yum >/dev/null 2>&1; then
        platform='centos'
    elif command -v brew >/dev/null 2>&1; then
        platform='mac'
    elif command -v apt >/dev/null 2>&1; then
        platform='debian'
    fi

    echo -e "${GREEN}📊 Detected platform: ${platform}${NC}"

    # run platform specific configuration
    eval "${FUNCNAME/::run/::${platform}}"

    echo -e "${GREEN}✅ Repository configuration completed successfully!${NC}"
}

# debian/ubuntu configuration
krun::config::rocky-repo::debian() {
    echo -e "${YELLOW}⚠️  This script is for Rocky Linux/CentOS systems only${NC}"
    echo -e "${YELLOW}   Debian/Ubuntu systems use different package managers${NC}"
    exit 1
}

# centos/rhel configuration
krun::config::rocky-repo::centos() {
    echo -e "${BLUE}🔧 Configuring Rocky Linux repositories on CentOS/RHEL...${NC}"

    # check if running as root or with sudo
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root or with sudo${NC}"
        exit 1
    fi

    # create backup directory
    echo -e "${BLUE}📦 Creating backup directory...${NC}"
    mkdir -p /etc/yum.repos.d/backup

    # backup existing rocky repos
    if ls /etc/yum.repos.d/rocky*.repo >/dev/null 2>&1; then
        echo -e "${BLUE}📦 Backing up existing Rocky repositories...${NC}"
        mv /etc/yum.repos.d/rocky*.repo /etc/yum.repos.d/backup/
        echo -e "${GREEN}✓ Existing repositories backed up${NC}"
    else
        echo -e "${YELLOW}⚠️  No existing Rocky repositories found${NC}"
    fi

    # create new rocky.repo with IPv4 mirrors
    echo -e "${BLUE}🔧 Creating new Rocky repository configuration...${NC}"
    cat >/etc/yum.repos.d/rocky.repo <<'EOF'
[baseos]
name=Rocky Linux $releasever - BaseOS
baseurl=http://mirrors.tuna.tsinghua.edu.cn/rocky/$releasever/BaseOS/$basearch/os/
enabled=1
gpgcheck=0
countme=1
metadata_expire=6h

[appstream]
name=Rocky Linux $releasever - AppStream
baseurl=http://mirrors.tuna.tsinghua.edu.cn/rocky/$releasever/AppStream/$basearch/os/
enabled=1
gpgcheck=0
countme=1
metadata_expire=6h

[extras]
name=Rocky Linux $releasever - Extras
baseurl=http://mirrors.tuna.tsinghua.edu.cn/rocky/$releasever/extras/$basearch/os/
enabled=1
gpgcheck=0
countme=1
metadata_expire=6h

[plus]
name=Rocky Linux $releasever - Plus
baseurl=http://mirrors.tuna.tsinghua.edu.cn/rocky/$releasever/plus/$basearch/os/
enabled=0
gpgcheck=0
countme=1
metadata_expire=6h

[crb]
name=Rocky Linux $releasever - CRB
baseurl=http://mirrors.tuna.tsinghua.edu.cn/rocky/$releasever/CRB/$basearch/os/
enabled=0
gpgcheck=0
countme=1
metadata_expire=6h

[highavailability]
name=Rocky Linux $releasever - High Availability
baseurl=http://mirrors.tuna.tsinghua.edu.cn/rocky/$releasever/HighAvailability/$basearch/os/
enabled=0
gpgcheck=0
countme=1
metadata_expire=6h

[resilientstorage]
name=Rocky Linux $releasever - Resilient Storage
baseurl=http://mirrors.tuna.tsinghua.edu.cn/rocky/$releasever/ResilientStorage/$basearch/os/
enabled=0
gpgcheck=0
countme=1
metadata_expire=6h

[nfv]
name=Rocky Linux $releasever - NFV
baseurl=http://mirrors.tuna.tsinghua.edu.cn/rocky/$releasever/NFV/$basearch/os/
enabled=0
gpgcheck=0
countme=1
metadata_expire=6h

[rt]
name=Rocky Linux $releasever - Realtime
baseurl=http://mirrors.tuna.tsinghua.edu.cn/rocky/$releasever/RT/$basearch/os/
enabled=0
gpgcheck=0
countme=1
metadata_expire=6h

[sap]
name=Rocky Linux $releasever - SAP
baseurl=http://mirrors.tuna.tsinghua.edu.cn/rocky/$releasever/SAP/$basearch/os/
enabled=0
gpgcheck=0
countme=1
metadata_expire=6h

[saphana]
name=Rocky Linux $releasever - SAPHANA
baseurl=http://mirrors.tuna.tsinghua.edu.cn/rocky/$releasever/SAPHANA/$basearch/os/
enabled=0
gpgcheck=0
countme=1
metadata_expire=6h
EOF

    echo -e "${GREEN}✓ Repository configuration file created${NC}"

    # clean and rebuild cache
    echo -e "${BLUE}🧹 Cleaning and rebuilding package cache...${NC}"
    if command -v dnf >/dev/null 2>&1; then
        dnf clean all
        dnf makecache
    else
        yum clean all
        yum makecache
    fi

    echo -e "${GREEN}✓ Package cache rebuilt${NC}"

    # run common verification
    krun::config::rocky-repo::common
}

# mac configuration
krun::config::rocky-repo::mac() {
    echo -e "${YELLOW}⚠️  This script is for Rocky Linux/CentOS systems only${NC}"
    echo -e "${YELLOW}   macOS systems use different package managers${NC}"
    exit 1
}

# common verification
krun::config::rocky-repo::common() {
    echo -e "${BLUE}🔍 Verifying repository configuration...${NC}"

    # check if package manager is available
    if ! command -v dnf >/dev/null 2>&1 && ! command -v yum >/dev/null 2>&1; then
        echo -e "${RED}❌ This script requires dnf or yum package manager${NC}"
        return 1
    fi

    # check if repository file exists
    if [[ ! -f /etc/yum.repos.d/rocky.repo ]]; then
        echo -e "${RED}❌ Rocky repository configuration not found${NC}"
        return 1
    fi

    echo -e "${GREEN}✓ Repository configuration verified${NC}"

    # show available repositories
    echo -e "${BLUE}📋 Available repositories:${NC}"
    if command -v dnf >/dev/null 2>&1; then
        dnf repolist 2>/dev/null || echo -e "${YELLOW}⚠️  Unable to list repositories${NC}"
    else
        yum repolist 2>/dev/null || echo -e "${YELLOW}⚠️  Unable to list repositories${NC}"
    fi

    # show backup information
    if [[ -d /etc/yum.repos.d/backup ]] && [[ -n "$(ls -A /etc/yum.repos.d/backup 2>/dev/null)" ]]; then
        echo -e "${BLUE}📦 Backup files saved to: /etc/yum.repos.d/backup/${NC}"
        echo -e "${YELLOW}   To restore: mv /etc/yum.repos.d/backup/*.repo /etc/yum.repos.d/${NC}"
    fi

    krun::config::rocky-repo::show_usage
}

# show usage information
krun::config::rocky-repo::show_usage() {
    echo -e "${BLUE}🚀 Repository Configuration Complete!${NC}"
    echo ""
    echo -e "${GREEN}Common package manager commands:${NC}"
    echo "  dnf repolist                    # List enabled repositories"
    echo "  dnf search <package>            # Search for packages"
    echo "  dnf install <package>           # Install packages"
    echo "  dnf update                      # Update system packages"
    echo "  dnf clean all                   # Clean package cache"
    echo ""
    echo -e "${GREEN}Repository management:${NC}"
    echo "  dnf config-manager --enable <repo>    # Enable repository"
    echo "  dnf config-manager --disable <repo>   # Disable repository"
    echo "  dnf repolist --enabled               # Show enabled repos"
    echo ""
    echo -e "${YELLOW}📚 Documentation:${NC}"
    echo "  https://docs.rockylinux.org/"
    echo "  https://mirrors.tuna.tsinghua.edu.cn/rocky/"
    echo ""
}

# run main
krun::config::rocky-repo::run "$@"
