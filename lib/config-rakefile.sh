#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-rakefile.sh | bash

# vars

# run code
krun::config::rakefile::run() {
    # default debian platform
    platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::config::rakefile::centos() {
    krun::config::rakefile::common
}

# debian code
krun::config::rakefile::debian() {
    krun::config::rakefile::common
}

# mac code
krun::config::rakefile::mac() {
    krun::config::rakefile::common
}

# common code
krun::config::rakefile::common() {
    local rakefile_path="./Rakefile"

    # check if Rakefile already exists
    if [[ -f "$rakefile_path" ]]; then
        echo "⚠️  Rakefile already exists, skipping..."
        echo "   Location: $rakefile_path"
        return 0
    fi

    # create Rakefile
    echo "Creating Rakefile..."
    cat >"$rakefile_path" <<'EOF'
# frozen_string_literal: true

# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

require 'time'

task default: %w[push]

task :push do
  system 'rubocop -A'
  system 'git add .'
  system "git commit -m \"Update #{Time.now}\""
  system 'git pull'
  system 'git push origin main'
end

task :run do
  system "echo 'running ...'"
end
EOF

    echo "✅ Rakefile created successfully"
    echo "   Location: $rakefile_path"
    echo ""
    echo "Available tasks:"
    echo "  rake push    # Format, commit and push changes"
    echo "  rake run     # Run the application"
}

# run main
krun::config::rakefile::run "$@"
