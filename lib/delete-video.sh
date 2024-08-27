#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# vars

# run code
krun::delete::video::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::delete::video::centos() {
    krun::delete::video::common
}

# debian code
krun::delete::video::debian() {
    krun::delete::video::common
}

# mac code
krun::delete::video::mac() {
    krun::delete::video::common
}

# common code
krun::delete::video::common() {
    mkdir -p /opt/scripts

    tee /opt/scripts/delete-video.sh <<EOF
#!/usr/bin/env bash

video_path="\${video_path_custom:-/data/record}"
find "\${video_path}" -mtime +30 -name "*.mp4" -exec rm -rf {} \;
echo "Delete 30 days ago video done."
EOF

    chmod +x /opt/scripts/delete-video.sh

    (
        crontab -l 2>/dev/null
        echo "0 3 * * * /opt/scripts/delete-video.sh"
    ) | crontab -
}

# run main
krun::delete::video::run "$@"
