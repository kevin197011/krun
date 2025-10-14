#!/usr/bin/env bash

# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-base-packages.sh | bash

# vars

# run code
krun::install::base_packages::run() {
    # default debian platform
    platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::base_packages::centos() {
    echo "Installing base packages on CentOS/RHEL..."

    # Update system and install EPEL
    if command -v dnf >/dev/null 2>&1; then
        dnf update -y
        dnf install -y epel-release
        dnf install -y \
            vim \
            git \
            tree \
            lrzsz \
            lsof \
            net-tools \
            openssl-devel \
            wget \
            ncdu \
            chrony \
            logrotate \
            net-snmp-utils \
            bind-utils \
            bash-completion \
            lvm2 \
            jq \
            unzip \
            telnet \
            sysstat \
            rsync
    else
        yum update -y
        yum install -y epel-release
        yum install -y \
            vim \
            git \
            tree \
            lrzsz \
            lsof \
            net-tools \
            openssl-devel \
            wget \
            ncdu \
            chrony \
            logrotate \
            net-snmp-utils \
            bind-utils \
            bash-completion \
            lvm2 \
            jq \
            unzip \
            telnet \
            sysstat \
            rsync
    fi

    krun::install::base_packages::common
}

# debian code
krun::install::base_packages::debian() {
    echo "Installing base packages on Debian/Ubuntu..."

    # Update package list
    apt-get update

    # Install packages
    apt-get install -y \
        vim \
        git \
        tree \
        lrzsz \
        lsof \
        net-tools \
        libssl-dev \
        wget \
        ncdu \
        chrony \
        logrotate \
        snmp-mibs-downloader \
        dnsutils \
        bash-completion \
        lvm2 \
        jq \
        unzip \
        telnet \
        sysstat \
        rsync

    krun::install::base_packages::common
}

# mac code
krun::install::base_packages::mac() {
    echo "Installing base packages on macOS..."

    # Check if Homebrew is installed
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Please install Homebrew first:"
        echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        exit 1
    fi

    # Install packages via Homebrew
    brew install \
        vim \
        git \
        tree \
        lrzsz \
        lsof \
        wget \
        ncdu \
        jq \
        unzip \
        telnet \
        rsync

    krun::install::base_packages::common
}

# common code
krun::install::base_packages::common() {
    echo "Configuring installed packages..."

    # Enable and start chrony/ntp service (Linux only)
    if [[ "$(uname)" != "Darwin" ]]; then
        if systemctl list-unit-files | grep -q chronyd; then
            systemctl enable chronyd
            systemctl start chronyd
            echo "✓ Chrony time synchronization enabled"
        elif systemctl list-unit-files | grep -q chrony; then
            systemctl enable chrony
            systemctl start chrony
            echo "✓ Chrony time synchronization enabled"
        elif systemctl list-unit-files | grep -q ntp; then
            systemctl enable ntp
            systemctl start ntp
            echo "✓ NTP time synchronization enabled"
        fi
    fi

    # Configure Git global settings (basic)
    if command -v git >/dev/null 2>&1; then
        git config --global init.defaultBranch main 2>/dev/null || true
        git config --global pull.rebase false 2>/dev/null || true
        echo "✓ Git basic configuration applied"
    fi

    # Enable bash completion
    if [[ -f /etc/bash_completion ]] && [[ -n "${BASH_VERSION:-}" ]]; then
        echo "✓ Bash completion available"
    fi

    # Create useful aliases
    if [[ ! -f /etc/profile.d/base-aliases.sh ]]; then
        tee /etc/profile.d/base-aliases.sh >/dev/null <<'EOF'
# Base system aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps aux'
alias top='top -c'
alias ..='cd ..'
alias ...='cd ../..'
EOF
        echo "✓ Base aliases created in /etc/profile.d/base-aliases.sh"
    fi

    echo "Base packages installation completed successfully!"
    echo ""
    echo "Installed packages:"
    echo "  - vim: Advanced text editor"
    echo "  - git: Version control system"
    echo "  - tree: Directory tree viewer"
    echo "  - lrzsz: File transfer utilities (rz/sz)"
    echo "  - lsof: List open files"
    echo "  - net-tools: Network utilities (netstat, ifconfig)"
    echo "  - openssl-devel/libssl-dev: SSL development libraries"
    echo "  - wget: Web file downloader"
    echo "  - ncdu: Disk usage analyzer"
    echo "  - chrony: Time synchronization"
    echo "  - logrotate: Log rotation utility"
    echo "  - net-snmp-utils/snmp-mibs-downloader: SNMP utilities"
    echo "  - bind-utils/dnsutils: DNS utilities (dig, nslookup)"
    echo "  - bash-completion: Command completion"
    echo "  - lvm2: Logical volume management"
    echo "  - jq: JSON processor"
    echo "  - unzip: Archive extraction"
    echo "  - telnet: Network testing tool"
    echo "  - sysstat: System performance tools"
    echo "  - rsync: File synchronization"
}

# run main
krun::install::base_packages::run "$@"
