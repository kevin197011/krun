#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-gcloud.sh | bash

# vars

# run code
krun::install::gcloud::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::gcloud::centos() {
    echo "Installing Google Cloud CLI on CentOS/RHEL..."

    # Add Google Cloud YUM repository
    cat >/etc/yum.repos.d/google-cloud-sdk.repo <<EOF
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

    # Install Google Cloud CLI
    yum install -y google-cloud-cli

    krun::install::gcloud::common
}

# debian code
krun::install::gcloud::debian() {
    echo "Installing Google Cloud CLI on Debian/Ubuntu..."

    # Install prerequisites
    apt-get update
    apt-get install -y apt-transport-https ca-certificates gnupg curl

    # Add Google Cloud APT repository
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    echo "deb https://packages.cloud.google.com/apt cloud-sdk main" >/etc/apt/sources.list.d/google-cloud-sdk.list

    # Install Google Cloud CLI
    apt-get update
    apt-get install -y google-cloud-cli

    krun::install::gcloud::common
}

# mac code
krun::install::gcloud::mac() {
    echo "Installing Google Cloud CLI on macOS..."

    if command -v brew >/dev/null 2>&1; then
        # Install via Homebrew
        brew install --cask google-cloud-sdk
        echo "✓ Google Cloud CLI installed via Homebrew"
        krun::install::gcloud::verify_installation
        return
    else
        echo "Homebrew not found, using manual installation..."
        krun::install::gcloud::common
    fi
}

# common code
krun::install::gcloud::common() {
    echo "Installing Google Cloud CLI manually..."

    # Detect architecture and OS
    local arch=$(uname -m)
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local download_url=""

    if [[ "$os" == "linux" ]]; then
        if [[ "$arch" == "x86_64" ]]; then
            download_url="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz"
        elif [[ "$arch" == "aarch64" ]]; then
            download_url="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-arm.tar.gz"
        else
            echo "Unsupported architecture: $arch"
            return 1
        fi
    elif [[ "$os" == "darwin" ]]; then
        if [[ "$arch" == "x86_64" ]]; then
            download_url="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-x86_64.tar.gz"
        elif [[ "$arch" == "arm64" ]]; then
            download_url="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-arm.tar.gz"
        else
            echo "Unsupported architecture: $arch"
            return 1
        fi
    else
        echo "Unsupported OS: $os"
        return 1
    fi

    # Download and install
    cd /tmp
    curl -L -o google-cloud-cli.tar.gz "$download_url"
    tar -xzf google-cloud-cli.tar.gz

    # Install to /usr/local (or user directory)
    local install_dir="/usr/local/google-cloud-sdk"
    if [[ ! -w "/usr/local" ]]; then
        install_dir="$HOME/google-cloud-sdk"
    fi

    rm -rf "$install_dir"
    mv google-cloud-sdk "$install_dir"

    # Run installer
    "$install_dir/install.sh" --quiet --path-update=true --command-completion=true

    # Add to PATH for current session
    export PATH="$install_dir/bin:$PATH"

    # Clean up
    rm -f google-cloud-cli.tar.gz
    cd -

    echo "✓ Google Cloud CLI installed to $install_dir"
    krun::install::gcloud::verify_installation
}

# Verify Google Cloud CLI installation
krun::install::gcloud::verify_installation() {
    echo "Verifying Google Cloud CLI installation..."

    # Check gcloud command
    if command -v gcloud >/dev/null 2>&1; then
        echo "✓ gcloud command is available"
        gcloud version
    else
        echo "✗ gcloud command not found"
        echo "You may need to restart your shell or run:"
        echo "  source ~/.bashrc"
        return 1
    fi

    # Check additional components
    if command -v gsutil >/dev/null 2>&1; then
        echo "✓ gsutil is available"
    fi

    if command -v bq >/dev/null 2>&1; then
        echo "✓ bq (BigQuery) is available"
    fi

    echo ""
    echo "=== Google Cloud CLI Installation Summary ==="
    echo "Version: $(gcloud version --format='value(Google Cloud SDK)' 2>/dev/null || echo 'Unknown')"
    echo "Executable: $(which gcloud)"
    echo ""
    echo "Next steps:"
    echo "1. Authenticate with Google Cloud:"
    echo "   gcloud auth login"
    echo ""
    echo "2. Set default project:"
    echo "   gcloud config set project PROJECT_ID"
    echo ""
    echo "3. Set default region/zone:"
    echo "   gcloud config set compute/region us-central1"
    echo "   gcloud config set compute/zone us-central1-a"
    echo ""
    echo "Common gcloud commands:"
    echo "  gcloud projects list              - List projects"
    echo "  gcloud compute instances list     - List VM instances"
    echo "  gcloud storage buckets list       - List storage buckets"
    echo "  gcloud config list               - Show configuration"
    echo "  gcloud components update         - Update components"
    echo ""
    echo "Google Cloud CLI is ready to use!"
}

# run main
krun::install::gcloud::run "$@"
