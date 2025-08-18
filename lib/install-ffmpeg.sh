#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-ffmpeg.sh | bash

# vars

# Detect system version and distribution
get_system_info() {
    local system_info=""

    if [[ -f /etc/redhat-release ]]; then
        local release_content=$(cat /etc/redhat-release)
        if echo "$release_content" | grep -q "Rocky Linux release 9"; then
            system_info="rocky9"
        elif echo "$release_content" | grep -q "CentOS Linux release 8"; then
            system_info="centos8"
        elif echo "$release_content" | grep -q "CentOS Linux release 7"; then
            system_info="centos7"
        elif echo "$release_content" | grep -q "Red Hat Enterprise Linux release 9"; then
            system_info="rhel9"
        elif echo "$release_content" | grep -q "Red Hat Enterprise Linux release 8"; then
            system_info="rhel8"
        elif echo "$release_content" | grep -q "Red Hat Enterprise Linux release 7"; then
            system_info="rhel7"
        else
            # Generic RHEL/CentOS detection
            local version=$(rpm -E %rhel 2>/dev/null || echo "7")
            system_info="el${version}"
        fi
    elif [[ -f /etc/debian_version ]]; then
        if [[ -f /etc/lsb-release ]]; then
            source /etc/lsb-release
            if [[ "$DISTRIB_ID" == "Ubuntu" ]]; then
                system_info="ubuntu${DISTRIB_RELEASE%%.*}"
            else
                system_info="debian"
            fi
        else
            system_info="debian"
        fi
    elif command -v brew >/dev/null 2>&1; then
        system_info="mac"
    else
        system_info="unknown"
    fi

    echo "$system_info"
}

# Download and install static FFmpeg build
install_static_ffmpeg() {
    echo "Downloading static FFmpeg build..."

    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    # Download latest static build
    local ffmpeg_url="https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"
    echo "Downloading from: $ffmpeg_url"

    if ! curl -L -o ffmpeg.tar.xz "$ffmpeg_url"; then
        echo "✗ Failed to download static FFmpeg build"
        rm -rf "$temp_dir"
        return 1
    fi

    # Extract and install
    echo "Extracting FFmpeg..."
    tar -xf ffmpeg.tar.xz

    # Find the extracted directory
    local ffmpeg_dir=$(find . -maxdepth 1 -type d -name "ffmpeg-*-amd64-static" | head -1)
    if [[ -z "$ffmpeg_dir" ]]; then
        echo "✗ Failed to find extracted FFmpeg directory"
        rm -rf "$temp_dir"
        return 1
    fi

    cd "$ffmpeg_dir"

    # Install binaries
    echo "Installing FFmpeg binaries to /usr/local/bin..."
    sudo cp ffmpeg ffprobe /usr/local/bin/ 2>/dev/null || cp ffmpeg ffprobe /usr/local/bin/

    # Clean up
    cd /
    rm -rf "$temp_dir"

    echo "✓ Static FFmpeg installed successfully"
    return 0
}

# run code
krun::install::ffmpeg::run() {
    local system_info=$(get_system_info)
    echo "Detected system: $system_info"

    case "$system_info" in
    rocky9 | rhel9 | el9)
        krun::install::ffmpeg::el9
        ;;
    centos8 | rhel8 | el8)
        krun::install::ffmpeg::el8
        ;;
    centos7 | rhel7 | el7)
        krun::install::ffmpeg::el7
        ;;
    ubuntu* | debian)
        krun::install::ffmpeg::debian
        ;;
    mac)
        krun::install::ffmpeg::mac
        ;;
    *)
        echo "Unsupported system: $system_info"
        echo "Trying generic installation..."
        krun::install::ffmpeg::generic
        ;;
    esac
}

# EL9 (Rocky Linux 9, RHEL 9) specific installation
krun::install::ffmpeg::el9() {
    echo "Installing FFmpeg on EL9 (Rocky Linux 9/RHEL 9)..."

    # Update system
    echo "Updating system packages..."
    sudo dnf -y update

    # Install EPEL and enable CRB
    echo "Installing EPEL and enabling CRB repository..."
    sudo dnf -y install epel-release dnf-plugins-core
    sudo dnf config-manager --set-enabled crb

    # Install RPM Fusion repositories
    echo "Installing RPM Fusion repositories..."
    sudo dnf -y install \
        https://download1.rpmfusion.org/free/el/rpmfusion-free-release-9.noarch.rpm \
        https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-9.noarch.rpm

    # Install critical dependencies first
    echo "Installing critical dependencies..."
    sudo dnf -y install ladspa rubberband-libs || true

    # Try package manager installation
    echo "Attempting package manager installation..."
    if sudo dnf -y install ffmpeg ffmpeg-devel --nobest; then
        echo "✓ FFmpeg installed successfully via package manager"
    else
        echo "Package manager installation failed, trying static build..."
        install_static_ffmpeg
    fi

    krun::install::ffmpeg::common
}

# EL8 (CentOS 8, RHEL 8) specific installation
krun::install::ffmpeg::el8() {
    echo "Installing FFmpeg on EL8 (CentOS 8/RHEL 8)..."

    # Update system
    echo "Updating system packages..."
    sudo dnf -y update

    # Install EPEL and enable PowerTools
    echo "Installing EPEL and enabling PowerTools repository..."
    sudo dnf -y install epel-release dnf-plugins-core
    sudo dnf config-manager --set-enabled powertools || sudo dnf config-manager --set-enabled PowerTools

    # Install RPM Fusion repositories
    echo "Installing RPM Fusion repositories..."
    sudo dnf -y install \
        https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm \
        https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-8.noarch.rpm

    # Install dependencies
    echo "Installing dependencies..."
    sudo dnf -y install ladspa rubberband-libs || true

    # Try package manager installation
    echo "Attempting package manager installation..."
    if sudo dnf -y install ffmpeg ffmpeg-devel --nobest; then
        echo "✓ FFmpeg installed successfully via package manager"
    else
        echo "Package manager installation failed, trying static build..."
        install_static_ffmpeg
    fi

    krun::install::ffmpeg::common
}

# EL7 (CentOS 7, RHEL 7) specific installation
krun::install::ffmpeg::el7() {
    echo "Installing FFmpeg on EL7 (CentOS 7/RHEL 7)..."

    # Update system
    echo "Updating system packages..."
    sudo yum -y update

    # Install EPEL
    echo "Installing EPEL repository..."
    sudo yum -y install epel-release

    # Install RPM Fusion repositories
    echo "Installing RPM Fusion repositories..."
    sudo yum -y install \
        https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm \
        https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-7.noarch.rpm

    # Install dependencies
    echo "Installing dependencies..."
    sudo yum -y install ladspa rubberband-libs || true

    # Try package manager installation
    echo "Attempting package manager installation..."
    if sudo yum -y install ffmpeg ffmpeg-devel --nobest; then
        echo "✓ FFmpeg installed successfully via package manager"
    else
        echo "Package manager installation failed, trying static build..."
        install_static_ffmpeg
    fi

    krun::install::ffmpeg::common
}

# Debian/Ubuntu installation
krun::install::ffmpeg::debian() {
    echo "Installing FFmpeg on Debian/Ubuntu..."

    # Update package lists
    echo "Updating package lists..."
    sudo apt-get update

    # Install FFmpeg
    echo "Installing FFmpeg..."
    if sudo apt-get install -y ffmpeg; then
        echo "✓ FFmpeg installed successfully"
    else
        echo "Standard installation failed, trying alternative repositories..."

        # Try to add additional repositories
        sudo apt-get install -y software-properties-common || true
        sudo add-apt-repository universe || true
        sudo apt-get update

        if sudo apt-get install -y ffmpeg; then
            echo "✓ FFmpeg installed successfully from universe repository"
        else
            echo "Package manager installation failed, trying static build..."
            install_static_ffmpeg
        fi
    fi

    krun::install::ffmpeg::common
}

# macOS installation
krun::install::ffmpeg::mac() {
    echo "Installing FFmpeg on macOS..."

    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew is required for FFmpeg installation on macOS"
        echo "Please install Homebrew first: https://brew.sh/"
        return 1
    fi

    # Update Homebrew
    echo "Updating Homebrew..."
    brew update

    # Install FFmpeg via Homebrew
    echo "Installing FFmpeg via Homebrew..."
    if brew install ffmpeg; then
        echo "✓ FFmpeg installed successfully via Homebrew"
    else
        echo "Homebrew installation failed, trying static build..."
        install_static_ffmpeg
    fi

    krun::install::ffmpeg::common
}

# Generic installation for unknown systems
krun::install::ffmpeg::generic() {
    echo "Attempting generic FFmpeg installation..."

    # Try common package managers
    if command -v dnf >/dev/null 2>&1; then
        echo "Trying DNF package manager..."
        if sudo dnf -y install ffmpeg; then
            echo "✓ FFmpeg installed successfully via DNF"
            krun::install::ffmpeg::common
            return 0
        fi
    fi

    if command -v yum >/dev/null 2>&1; then
        echo "Trying YUM package manager..."
        if sudo yum -y install ffmpeg; then
            echo "✓ FFmpeg installed successfully via YUM"
            krun::install::ffmpeg::common
            return 0
        fi
    fi

    if command -v apt-get >/dev/null 2>&1; then
        echo "Trying APT package manager..."
        if sudo apt-get update && sudo apt-get install -y ffmpeg; then
            echo "✓ FFmpeg installed successfully via APT"
            krun::install::ffmpeg::common
            return 0
        fi
    fi

    # Fallback to static build
    echo "All package managers failed, trying static build..."
    install_static_ffmpeg
    krun::install::ffmpeg::common
}

# common code
krun::install::ffmpeg::common() {
    echo "Verifying FFmpeg installation..."

    # Check if FFmpeg is installed
    if ! command -v ffmpeg >/dev/null 2>&1; then
        echo "✗ FFmpeg installation failed or not found in PATH"
        echo "Please check the installation logs above for errors."
        echo ""
        echo "Troubleshooting tips:"
        echo "1. Make sure you have sufficient permissions (run as root/sudo)"
        echo "2. Check if your system has the required repositories enabled"
        echo "3. Try updating your package manager: yum update or apt-get update"
        echo "4. For dependency issues, try: yum install -y --nobest ffmpeg"
        return 1
    fi

    echo "✓ FFmpeg installed successfully"
    echo "Version information:"
    ffmpeg -version | head -1

    # Check for additional tools
    local tools_available=0
    local total_tools=3

    if command -v ffprobe >/dev/null 2>&1; then
        echo "✓ ffprobe is available"
        ((tools_available++))
    else
        echo "⚠ ffprobe not found (may be included in ffmpeg package)"
    fi

    if command -v ffplay >/dev/null 2>&1; then
        echo "✓ ffplay is available"
        ((tools_available++))
    else
        echo "⚠ ffplay not found (may be included in ffmpeg package)"
    fi

    if command -v ffmpeg >/dev/null 2>&1; then
        echo "✓ ffmpeg is available"
        ((tools_available++))
    fi

    echo ""
    echo "=== FFmpeg Installation Summary ==="
    echo "Version: $(ffmpeg -version | head -1)"
    echo "Executable: $(which ffmpeg)"
    echo "Tools available: $tools_available/$total_tools"
    echo ""

    # Show supported formats and codecs
    echo "Supported formats:"
    ffmpeg -formats 2>/dev/null | grep -E "^[DE]" | head -5 | sed 's/^/  /'
    echo "  ... (showing first 5, run 'ffmpeg -formats' for full list)"
    echo ""

    echo "Supported codecs:"
    ffmpeg -codecs 2>/dev/null | grep -E "^[DE]" | head -5 | sed 's/^/  /'
    echo "  ... (showing first 5, run 'ffmpeg -codecs' for full list)"
    echo ""

    echo "Common FFmpeg commands:"
    echo "  ffmpeg -i input.mp4 output.avi           - Convert video format"
    echo "  ffmpeg -i input.mp4 -vn output.mp3       - Extract audio"
    echo "  ffmpeg -i input.mp4 -ss 00:01:00 -t 10 -c copy output.mp4  - Cut video"
    echo "  ffmpeg -i input.mp4 -vf scale=1280:720 output.mp4  - Resize video"
    echo "  ffmpeg -i input.mp4 -r 30 output.mp4     - Change frame rate"
    echo "  ffprobe input.mp4                        - Get file information"
    echo ""
    echo "Video quality options:"
    echo "  -crf 23        - Constant Rate Factor (0-51, lower = better)"
    echo "  -b:v 1M        - Video bitrate"
    echo "  -b:a 128k      - Audio bitrate"
    echo ""
    echo "Hardware acceleration (if supported):"
    echo "  -hwaccel auto  - Use hardware acceleration"
    echo ""
    echo "FFmpeg is ready to use!"
}

# run main
krun::install::ffmpeg::run "$@"
