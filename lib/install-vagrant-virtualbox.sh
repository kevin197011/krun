#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-vagrant-virtualbox.sh | bash

# vars
vagrant_version=${vagrant_version:-latest}
virtualbox_version=${virtualbox_version:-latest}

# run code
krun::install::vagrant-virtualbox::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::vagrant-virtualbox::centos() {
    echo "Installing Vagrant and VirtualBox on CentOS/RHEL..."

    # Install dependencies
    yum install -y epel-release wget curl
    yum install -y gcc dkms make qt libgomp patch
    yum install -y kernel-headers kernel-devel binutils glibc-headers glibc-devel fontforge

    # Install VirtualBox
    wget http://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo -O /etc/yum.repos.d/virtualbox.repo
    yum install -y VirtualBox-5.2

    # Install Vagrant
    yum install -y https://releases.hashicorp.com/vagrant/2.2.19/vagrant_2.2.19_x86_64.rpm

    krun::install::vagrant-virtualbox::common
}

# debian code
krun::install::vagrant-virtualbox::debian() {
    echo "Installing Vagrant and VirtualBox on Debian/Ubuntu..."

    # Update package lists
    apt-get update

    # Install VirtualBox
    apt-get install -y virtualbox virtualbox-ext-pack

    # Install Vagrant
    local vagrant_deb="vagrant_2.3.7-1_amd64.deb"
    local vagrant_url="https://releases.hashicorp.com/vagrant/2.3.7/${vagrant_deb}"

    curl -fsSL "$vagrant_url" -o "/tmp/${vagrant_deb}"
    apt-get install -y "/tmp/${vagrant_deb}"
    rm -f "/tmp/${vagrant_deb}"

    krun::install::vagrant-virtualbox::common
}

# mac code
krun::install::vagrant-virtualbox::mac() {
    echo "Installing Vagrant and VirtualBox on macOS..."

    if command -v brew >/dev/null 2>&1; then
        # Install VirtualBox
        brew install --cask virtualbox

        # Install Vagrant
        brew install --cask vagrant

        # Install Vagrant Manager (optional)
        brew install --cask vagrant-manager || echo "⚠ Vagrant Manager installation failed"

        echo "✓ Vagrant and VirtualBox installed via Homebrew"
        krun::install::vagrant-virtualbox::verify_installation
        krun::install::vagrant-virtualbox::install_boxes
        return
    fi

    echo "Homebrew not found. Please install Homebrew first:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    return 1
}

# common code
krun::install::vagrant-virtualbox::common() {
    echo "Configuring Vagrant and VirtualBox..."

    # Verify installations
    krun::install::vagrant-virtualbox::verify_installation

    # Install common Vagrant boxes
    krun::install::vagrant-virtualbox::install_boxes
}

# Verify installations
krun::install::vagrant-virtualbox::verify_installation() {
    echo "Verifying installations..."

    # Check VirtualBox
    if command -v VBoxManage >/dev/null 2>&1; then
        echo "✓ VirtualBox is available"
        VBoxManage --version
    else
        echo "✗ VirtualBox not found"
    fi

    # Check Vagrant
    if command -v vagrant >/dev/null 2>&1; then
        echo "✓ Vagrant is available"
        vagrant --version
    else
        echo "✗ Vagrant not found"
        return 1
    fi

    echo ""
    echo "=== Installation Summary ==="
    echo "VirtualBox: $(VBoxManage --version 2>/dev/null || echo 'not found')"
    echo "Vagrant: $(vagrant --version 2>/dev/null || echo 'not found')"
    echo ""
    echo "Common commands:"
    echo "  vagrant init <box>              - Initialize Vagrant project"
    echo "  vagrant up                      - Start VM"
    echo "  vagrant ssh                     - SSH into VM"
    echo "  vagrant halt                    - Stop VM"
    echo "  vagrant destroy                 - Destroy VM"
    echo "  vagrant box list               - List available boxes"
    echo ""
    echo "Example: Create a new VM"
    echo "  mkdir my-vm && cd my-vm"
    echo "  vagrant init centos/7"
    echo "  vagrant up"
    echo ""
    echo "Vagrant and VirtualBox are ready to use!"
}

# Install common Vagrant boxes
krun::install::vagrant-virtualbox::install_boxes() {
    echo "Installing common Vagrant boxes..."

    local boxes=(
        "centos/7"
        "ubuntu/focal64"
        "debian/bullseye64"
    )

    for box in "${boxes[@]}"; do
        echo "Adding box: $box"
        vagrant box add "$box" --provider virtualbox 2>/dev/null || echo "⚠ Failed to add box: $box"
    done

    echo "Available boxes:"
    vagrant box list 2>/dev/null || echo "No boxes available"
}

# run main
krun::install::vagrant-virtualbox::run "$@"
