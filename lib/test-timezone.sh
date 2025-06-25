#!/usr/bin/env bash

# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# vars
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Test timezone setting
test_timezone_setting() {
    echo -e "${BLUE}🕐 Testing timezone setting to Asia/Shanghai...${NC}"

    # Show current timezone status
    echo -e "${CYAN}📊 Current timezone information:${NC}"
    if command -v timedatectl >/dev/null 2>&1; then
        echo -e "${BLUE}Using timedatectl:${NC}"
        timedatectl status || true
    fi

    echo -e "${BLUE}Current /etc/localtime:${NC}"
    ls -la /etc/localtime || true

    echo -e "${BLUE}Current /etc/timezone:${NC}"
    cat /etc/timezone 2>/dev/null || echo "File does not exist"

    echo -e "${BLUE}Current date:${NC}"
    date

    echo -e "${CYAN}📝 Available timezone files:${NC}"
    ls -la /usr/share/zoneinfo/Asia/Shanghai || echo "Shanghai timezone file not found"

    # Method 1: Try timedatectl (systemd)
    echo -e "\n${CYAN}🔧 Attempting to set timezone...${NC}"
    if command -v timedatectl >/dev/null 2>&1; then
        echo -e "${BLUE}Method 1: Using timedatectl${NC}"
        if timedatectl set-timezone Asia/Shanghai 2>/dev/null; then
            echo -e "${GREEN}✓ Timezone set to Asia/Shanghai using timedatectl${NC}"
        else
            echo -e "${YELLOW}⚠️  timedatectl failed, trying alternative method${NC}"

            # Method 2: Manual timezone file copy
            echo -e "${BLUE}Method 2: Manual timezone configuration${NC}"
            if [[ -f /usr/share/zoneinfo/Asia/Shanghai ]]; then
                # Backup current localtime
                if [[ -f /etc/localtime ]]; then
                    cp /etc/localtime /etc/localtime.backup.$(date +%Y%m%d%H%M%S) || true
                fi

                # Set new timezone
                ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
                echo 'Asia/Shanghai' >/etc/timezone 2>/dev/null || true
                echo -e "${GREEN}✓ Timezone set to Asia/Shanghai using manual method${NC}"
            else
                echo -e "${RED}✗ Failed to set timezone: /usr/share/zoneinfo/Asia/Shanghai not found${NC}"
                echo -e "${BLUE}Available Asia timezones:${NC}"
                ls /usr/share/zoneinfo/Asia/ | grep -i shanghai || echo "No Shanghai timezone found"
                ls /usr/share/zoneinfo/Asia/ | head -10 || true
            fi
        fi
    else
        # Method 2: Manual timezone file copy for systems without timedatectl
        echo -e "${BLUE}timedatectl not available, using manual method...${NC}"
        if [[ -f /usr/share/zoneinfo/Asia/Shanghai ]]; then
            # Backup current localtime
            if [[ -f /etc/localtime ]]; then
                cp /etc/localtime /etc/localtime.backup.$(date +%Y%m%d%H%M%S) || true
            fi

            # Set new timezone
            ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
            echo 'Asia/Shanghai' >/etc/timezone 2>/dev/null || true
            echo -e "${GREEN}✓ Timezone set to Asia/Shanghai using manual method${NC}"
        else
            echo -e "${RED}✗ Failed to set timezone: /usr/share/zoneinfo/Asia/Shanghai not found${NC}"
            echo -e "${BLUE}Available Asia timezones:${NC}"
            ls /usr/share/zoneinfo/Asia/ | grep -i shanghai || echo "No Shanghai timezone found"
            ls /usr/share/zoneinfo/Asia/ | head -10 || true
        fi
    fi

    # Verify timezone setting
    echo -e "\n${CYAN}🔍 Verifying timezone setting...${NC}"
    if command -v timedatectl >/dev/null 2>&1; then
        echo -e "${BLUE}timedatectl status:${NC}"
        timedatectl status | grep -E "(Time zone|Local time)" || true
    fi

    echo -e "${BLUE}Current /etc/localtime:${NC}"
    ls -la /etc/localtime || true

    echo -e "${BLUE}Current /etc/timezone:${NC}"
    cat /etc/timezone 2>/dev/null || echo "File does not exist"

    echo -e "${BLUE}Current timezone (from readlink):${NC}"
    readlink /etc/localtime | sed 's|/usr/share/zoneinfo/||' || echo "Unable to read link"

    echo -e "${BLUE}Current date and time:${NC}"
    date

    echo -e "${BLUE}System uptime:${NC}"
    uptime || true

    # Additional verification
    echo -e "\n${CYAN}🧪 Additional checks...${NC}"

    # Check if hardware clock is set
    if command -v hwclock >/dev/null 2>&1; then
        echo -e "${BLUE}Hardware clock:${NC}"
        hwclock --show 2>/dev/null || echo "Unable to read hardware clock"
    fi

    # Check timezone environment variable
    echo -e "${BLUE}TZ environment variable:${NC}"
    echo "${TZ:-Not set}"

    # Test with specific timezone
    echo -e "${BLUE}Test with TZ=Asia/Shanghai:${NC}"
    TZ=Asia/Shanghai date || true

    echo -e "${GREEN}✅ Timezone test completed!${NC}"
}

# Run test
test_timezone_setting "$@"
