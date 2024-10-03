#!/usr/bin/env bash
# Copyright (c) 2024 kk
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
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::ffmpeg::centos() {
    yum install epel-release -y
    yum localinstall --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm -y
    yum install ffmpeg ffmpeg-devel -y
    krun::install::ffmpeg::common
}

# debian code
krun::install::ffmpeg::debian() {
    krun::install::ffmpeg::common
}

# mac code
krun::install::ffmpeg::mac() {
    krun::install::ffmpeg::common
}

# common code
krun::install::ffmpeg::common() {
    ffmpeg -version
}

# run main
krun::install::ffmpeg::run "$@"
