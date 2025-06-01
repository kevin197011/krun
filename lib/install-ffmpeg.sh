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

    # Install EPEL repository
    yum install -y epel-release

    # Install RPM Fusion repository for FFmpeg
    yum install -y https://download1.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm || true
    yum install -y https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm || true

    # Install FFmpeg
    yum install -y ffmpeg ffmpeg-devel

    krun::install::ffmpeg::common
}

# debian code
krun::install::ffmpeg::debian() {
    echo "Installing FFmpeg on Debian/Ubuntu..."

    # Update package lists
    apt-get update

    # Install FFmpeg
    apt-get install -y ffmpeg

    krun::install::ffmpeg::common
}

# mac code
krun::install::ffmpeg::mac() {
    echo "Installing FFmpeg on macOS..."

    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew is required for FFmpeg installation on macOS"
        return 1
    fi

    # Install FFmpeg via Homebrew
    brew install ffmpeg

    krun::install::ffmpeg::common
}

# common code
krun::install::ffmpeg::common() {
    echo "Verifying FFmpeg installation..."

    # Check if FFmpeg is installed
    if ! command -v ffmpeg >/dev/null 2>&1; then
        echo "✗ FFmpeg installation failed"
        return 1
    fi

    echo "✓ FFmpeg installed successfully"
    ffmpeg -version | head -1

    # Check for additional tools
    if command -v ffprobe >/dev/null 2>&1; then
        echo "✓ ffprobe is available"
    fi

    if command -v ffplay >/dev/null 2>&1; then
        echo "✓ ffplay is available"
    fi

    echo ""
    echo "=== FFmpeg Installation Summary ==="
    echo "Version: $(ffmpeg -version | head -1)"
    echo "Executable: $(which ffmpeg)"
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
