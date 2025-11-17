#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-awscli.sh | bash

# vars

# run code
krun::install::awscli::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::awscli::centos() {
    echo "Installing AWS CLI on CentOS/RHEL..."

    # Install prerequisites
    yum install -y curl unzip

    krun::install::awscli::common
}

# debian code
krun::install::awscli::debian() {
    echo "Installing AWS CLI on Debian/Ubuntu..."

    # Install prerequisites
    apt-get update
    apt-get install -y curl unzip

    krun::install::awscli::common
}

# mac code
krun::install::awscli::mac() {
    echo "Installing AWS CLI on macOS..."

    # Try Homebrew first
    if command -v brew >/dev/null 2>&1; then
        brew install awscli
        echo "✓ AWS CLI installed via Homebrew"
        krun::install::awscli::verify_installation
        return
    else
        echo "Homebrew not found, using installer..."
        krun::install::awscli::common
    fi
}

# common code
krun::install::awscli::common() {
    echo "Installing AWS CLI v2..."

    # Detect architecture
    local arch=$(uname -m)
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local download_url=""

    # Determine download URL
    if [[ "$os" == "linux" ]]; then
        if [[ "$arch" == "x86_64" ]]; then
            download_url="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
        elif [[ "$arch" == "aarch64" ]]; then
            download_url="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
        else
            echo "Unsupported architecture: $arch"
            return 1
        fi
    elif [[ "$os" == "darwin" ]]; then
        download_url="https://awscli.amazonaws.com/AWSCLIV2.pkg"
    else
        echo "Unsupported OS: $os"
        return 1
    fi

    # Download and install
    cd /tmp

    if [[ "$os" == "darwin" ]]; then
        # macOS installer
        curl -L -o "AWSCLIV2.pkg" "$download_url"
        installer -pkg AWSCLIV2.pkg -target /
        rm AWSCLIV2.pkg
    else
        # Linux installer
        curl -L -o "awscliv2.zip" "$download_url"
        unzip -q awscliv2.zip
        ./aws/install
        rm -rf awscliv2.zip aws/
    fi

    cd -

    echo "✓ AWS CLI installed"
    krun::install::awscli::verify_installation
}

# Verify AWS CLI installation
krun::install::awscli::verify_installation() {
    echo "Verifying AWS CLI installation..."

    # Check aws command
    if command -v aws >/dev/null 2>&1; then
        echo "✓ aws command is available"
        aws --version
    else
        echo "✗ aws command not found"
        return 1
    fi

    echo ""
    echo "=== AWS CLI Installation Summary ==="
    echo "Version: $(aws --version)"
    echo "Executable: $(which aws)"
    echo ""
    echo "Next steps:"
    echo "1. Configure AWS credentials:"
    echo "   aws configure"
    echo ""
    echo "2. Or set environment variables:"
    echo "   export AWS_ACCESS_KEY_ID=your_access_key"
    echo "   export AWS_SECRET_ACCESS_KEY=your_secret_key"
    echo "   export AWS_DEFAULT_REGION=us-east-1"
    echo ""
    echo "3. Test configuration:"
    echo "   aws sts get-caller-identity"
    echo ""
    echo "Common AWS CLI commands:"
    echo "  aws s3 ls                    - List S3 buckets"
    echo "  aws ec2 describe-instances   - List EC2 instances"
    echo "  aws iam list-users           - List IAM users"
    echo "  aws configure list           - Show current configuration"
    echo ""
    echo "AWS CLI is ready to use!"
}

# run main
krun::install::awscli::run "$@"
