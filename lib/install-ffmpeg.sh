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

# Detect system version
get_system_version() {
    if command -v rpm >/dev/null 2>&1; then
        rpm -E %rhel 2>/dev/null || echo "7"
    else
        echo "unknown"
    fi
}

# Error handling function
handle_installation_error() {
    local error_msg="$1"
    echo "Error: $error_msg"
    echo "Trying alternative installation methods..."
    return 1
}

# run code
krun::install::ffmpeg::run() {
    # default debian platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::ffmpeg::centos() {
    echo "Installing FFmpeg on CentOS/RHEL..."

    local system_version=$(get_system_version)
    echo "Detected system version: EL $system_version"

    # Install EPEL repository
    yum install -y epel-release

    # Install RPM Fusion repository for FFmpeg
    echo "Installing RPM Fusion repositories..."
    yum install -y https://download1.rpmfusion.org/free/el/rpmfusion-free-release-${system_version}.noarch.rpm || true
    yum install -y https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-${system_version}.noarch.rpm || true

    # Update package cache
    echo "Updating package cache..."
    yum update -y

    # Install required dependencies first
    echo "Installing required dependencies..."

    # Core dependencies that are commonly needed
    local core_deps="ladspa libass libbluray libcdio libdrm libfdk-aac libmodplug libmp3lame libogg libtheora libvorbis libvpx libx264 libx265 libxvid opus rubberband speex wavpack xvidcore"

    # Try to install core dependencies
    for dep in $core_deps; do
        echo "Installing $dep..."
        yum install -y "$dep" || echo "Warning: Failed to install $dep, continuing..."
    done

    # Try to install FFmpeg with dependency resolution
    echo "Installing FFmpeg..."

    # Method 1: Standard installation
    if yum install -y ffmpeg ffmpeg-devel; then
        echo "✓ FFmpeg installed successfully via standard method"
    else
        echo "Standard installation failed, trying alternative approaches..."

        # Method 2: Install with --nobest to resolve version conflicts
        if yum install -y --nobest ffmpeg ffmpeg-devel; then
            echo "✓ FFmpeg installed successfully via --nobest method"
        else
            echo "Alternative installation failed, trying minimal installation..."

            # Method 3: Install only ffmpeg without ffmpeg-devel
            if yum install -y --nobest ffmpeg; then
                echo "✓ FFmpeg installed successfully (without development headers)"
            else
                echo "All RPM Fusion methods failed. Trying EPEL only..."

                # Method 4: Disable RPM Fusion temporarily and try EPEL only
                yum-config-manager --disable rpmfusion-free rpmfusion-free-updates rpmfusion-nonfree rpmfusion-nonfree-updates || true
                if yum install -y ffmpeg; then
                    echo "✓ FFmpeg installed successfully from EPEL"
                else
                    echo "EPEL installation also failed. Trying to compile from source..."

                    # Method 5: Last resort - try to install from source or alternative repos
                    install_ffmpeg_from_alternative_source
                fi

                # Re-enable RPM Fusion
                yum-config-manager --enable rpmfusion-free rpmfusion-free-updates rpmfusion-nonfree rpmfusion-nonfree-updates || true
            fi
        fi
    fi

    krun::install::ffmpeg::common
}

# Alternative installation method for problematic systems
install_ffmpeg_from_alternative_source() {
    echo "Attempting to install FFmpeg from alternative source..."

    # Try to install from AppStream (for RHEL 8/9)
    if yum install -y --enablerepo=AppStream ffmpeg; then
        echo "✓ FFmpeg installed successfully from AppStream"
        return 0
    fi

    # Try to install from PowerTools (for CentOS 8)
    if yum install -y --enablerepo=PowerTools ffmpeg; then
        echo "✓ FFmpeg installed successfully from PowerTools"
        return 0
    fi

    # Try to install from CRB (for RHEL 9)
    if yum install -y --enablerepo=CRB ffmpeg; then
        echo "✓ FFmpeg installed successfully from CRB"
        return 0
    fi

    echo "✗ All installation methods failed. Please install FFmpeg manually."
    echo "You can try:"
    echo "  1. yum install -y --enablerepo=AppStream ffmpeg"
    echo "  2. yum install -y --enablerepo=PowerTools ffmpeg"
    echo "  3. Download and compile from source: https://ffmpeg.org/download.html"
    return 1
}

# debian code
krun::install::ffmpeg::debian() {
    echo "Installing FFmpeg on Debian/Ubuntu..."

    # Update package lists
    apt-get update

    # Install FFmpeg with fallback options
    if apt-get install -y ffmpeg; then
        echo "✓ FFmpeg installed successfully"
    else
        echo "Standard installation failed, trying alternative repositories..."

        # Try to add additional repositories if needed
        apt-get install -y software-properties-common || true

        # Try to add universe repository (for Ubuntu)
        add-apt-repository universe || true
        apt-get update

        if apt-get install -y ffmpeg; then
            echo "✓ FFmpeg installed successfully from universe repository"
        else
            echo "✗ FFmpeg installation failed. Please install manually:"
            echo "  sudo apt-get install -y ffmpeg"
            return 1
        fi
    fi

    krun::install::ffmpeg::common
}

# mac code
krun::install::ffmpeg::mac() {
    echo "Installing FFmpeg on macOS..."

    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew is required for FFmpeg installation on macOS"
        echo "Please install Homebrew first: https://brew.sh/"
        return 1
    fi

    # Update Homebrew
    brew update

    # Install FFmpeg via Homebrew
    if brew install ffmpeg; then
        echo "✓ FFmpeg installed successfully via Homebrew"
    else
        echo "✗ FFmpeg installation failed. Please try manually:"
        echo "  brew install ffmpeg"
        return 1
    fi

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
