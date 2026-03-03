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
RUBY_HTTP_PORT="${RUBY_HTTP_PORT:-8080}"
RUBY_HTTP_ROOT="${RUBY_HTTP_ROOT:-.}"

# run code
krun::config::ruby_http::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::ruby_http::centos() {
    if ! command -v ruby >/dev/null 2>&1; then
        local sudo=""
        [[ "$(id -u 2>/dev/null || echo 1)" -ne 0 ]] && command -v sudo >/dev/null 2>&1 && sudo="sudo"
        command -v dnf >/dev/null 2>&1 && $sudo dnf -y install ruby ruby-devel || $sudo yum -y install ruby ruby-devel
    fi
    krun::config::ruby_http::ensure_gems
    krun::config::ruby_http::common
}

# debian code
krun::config::ruby_http::debian() {
    if ! command -v ruby >/dev/null 2>&1; then
        local sudo=""
        [[ "$(id -u 2>/dev/null || echo 1)" -ne 0 ]] && command -v sudo >/dev/null 2>&1 && sudo="sudo"
        $sudo apt-get update -qq || true
        $sudo apt-get install -y ruby ruby-dev
    fi
    krun::config::ruby_http::ensure_gems
    krun::config::ruby_http::common
}

# mac code
krun::config::ruby_http::mac() {
    if ! command -v ruby >/dev/null 2>&1; then
        command -v brew >/dev/null 2>&1 || { echo "Ruby not found. Install: krun install-ruby.sh"; exit 1; }
        brew install ruby
    fi
    krun::config::ruby_http::ensure_gems
    krun::config::ruby_http::common
}

krun::config::ruby_http::ensure_gems() {
    # Ruby 3.0+ 需单独安装 webrick，否则 ruby -run -e httpd 会报错
    gem list webrick -i >/dev/null 2>&1 || gem install webrick --no-document
    gem list bundler -i >/dev/null 2>&1 || gem install bundler --no-document
}

# common code
krun::config::ruby_http::common() {
    ruby -run -e httpd "$RUBY_HTTP_ROOT" -p "$RUBY_HTTP_PORT"
}

# run main
krun::config::ruby_http::run "$@"
