#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-ruby-http.sh | bash

# vars

# run code
krun::config::ruby-http::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::ruby-http::centos() {
    krun::config::ruby-http::common
}

# debian code
krun::config::ruby-http::debian() {
    krun::config::ruby-http::common
}

# mac code
krun::config::ruby-http::mac() {
    krun::config::ruby-http::common
}

# common code
krun::config::ruby-http::common() {
    ruby -run -e httpd . -p 8080 -b 0.0.0.0
}

# run main
krun::config::ruby-http::run "$@"
