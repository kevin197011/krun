#!/usr/bin/env bash
# Copyright (c) 2025 kk
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
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::ffmpeg::centos() {
    echo "Installing FFmpeg on CentOS/RHEL..."

    # Detect system version
    local system_version=$(rpm -E %rhel 2>/dev/null || echo "7")
    echo "Detected system version: EL $system_version"

    # Install EPEL repository
    if command -v dnf >/dev/null 2>&1; then
        dnf install -y epel-release dnf-plugins-core
        dnf config-manager --set-enabled crb 2>/dev/null || true
    else
        yum install -y epel-release
    fi

    # Install RPM Fusion repositories
    if command -v dnf >/dev/null 2>&1; then
        dnf install -y \
            https://download1.rpmfusion.org/free/el/rpmfusion-free-release-${system_version}.noarch.rpm \
            https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-${system_version}.noarch.rpm
    else
        yum install -y \
            https://download1.rpmfusion.org/free/el/rpmfusion-free-release-${system_version}.noarch.rpm \
            https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-${system_version}.noarch.rpm
    fi

    # Install critical dependencies
    if command -v dnf >/dev/null 2>&1; then
        dnf install -y ladspa rubberband-libs || true
        dnf install -y ffmpeg ffmpeg-devel --nobest || krun::install::ffmpeg::static_install
    else
        yum install -y ladspa rubberband-libs || true
        yum install -y ffmpeg ffmpeg-devel --nobest || krun::install::ffmpeg::static_install
    fi

    krun::install::ffmpeg::common
}

# debian code
krun::install::ffmpeg::debian() {
    echo "Installing FFmpeg on Debian/Ubuntu..."

    apt-get update
    apt-get install -y ffmpeg || krun::install::ffmpeg::static_install

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

    brew update
    brew install ffmpeg || krun::install::ffmpeg::static_install

    krun::install::ffmpeg::common
}

# static installation
krun::install::ffmpeg::static_install() {
    echo "Installing FFmpeg from static build..."

    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    # Download latest static build
    local ffmpeg_url="https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"
    echo "Downloading from: $ffmpeg_url"

    if ! curl -L -o ffmpeg.tar.xz "$ffmpeg_url"; then
        echo "Failed to download static FFmpeg build"
        rm -rf "$temp_dir"
        return 1
    fi

    # Extract and install
    tar -xf ffmpeg.tar.xz

    # Find the extracted directory
    local ffmpeg_dir=$(find . -maxdepth 1 -type d -name "ffmpeg-*-amd64-static" | head -1)
    if [[ -z "$ffmpeg_dir" ]]; then
        echo "Failed to find extracted FFmpeg directory"
        rm -rf "$temp_dir"
        return 1
    fi

    cd "$ffmpeg_dir"

    # Install binaries
    cp ffmpeg ffprobe /usr/local/bin/ 2>/dev/null || sudo cp ffmpeg ffprobe /usr/local/bin/

    # Clean up
    cd /
    rm -rf "$temp_dir"

    echo "Static FFmpeg installed successfully"
}

# common code
krun::install::ffmpeg::common() {
    echo "Verifying FFmpeg installation..."

    if ! command -v ffmpeg >/dev/null 2>&1; then
        echo "FFmpeg installation failed"
        return 1
    fi

    echo "FFmpeg installed successfully"
    ffmpeg -version | head -1

    # Check for additional tools
    if command -v ffprobe >/dev/null 2>&1; then
        echo "ffprobe is available"
    fi

    if command -v ffplay >/dev/null 2>&1; then
        echo "ffplay is available"
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
