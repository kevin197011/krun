#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config-rakefile.sh | bash
#
# Idempotent: overwrites ./Rakefile, ./push.rb; ensures kk-git (and bundler) gems are installed.

# vars
rakefile_path=${rakefile_path:-./Rakefile}
push_rb_path=${push_rb_path:-./push.rb}

# run code
krun::config::rakefile::run() {
    local platform='debian'
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

krun::config::rakefile::install_gems() {
    command -v gem >/dev/null 2>&1 || {
        echo "✗ gem not found; install Ruby first (lib/install-ruby.sh)"
        return 1
    }

    if ! gem list bundler -i >/dev/null 2>&1; then
        echo "Installing bundler..."
        gem install bundler --no-document
    else
        echo "✓ bundler already installed"
    fi

    if ! gem list kk-git -i >/dev/null 2>&1; then
        echo "Installing kk-git..."
        gem install kk-git --no-document
    else
        echo "✓ kk-git already installed"
    fi
}

# common code
krun::config::rakefile::common() {
    krun::config::rakefile::install_gems

    echo "Writing Rakefile..."
    cat >"$rakefile_path" <<'EOF'
# frozen_string_literal: true

# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

require 'bundler/setup'
require 'kk/git/rake_tasks'

task default: %w[push]

task :push do
  Rake::Task['git:auto_commit_push'].invoke
end

task :run do
  system 'docker compose down'
  system 'docker compose up -d --build --remove-orphans'
  # system 'docker compose logs -f'
end
EOF

    echo "✓ Rakefile written: ${rakefile_path}"

    echo "Writing push.rb..."
    cat >"$push_rb_path" <<'EOF'
# frozen_string_literal: true

# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

system 'rake'
EOF

    echo "✓ push.rb written: ${push_rb_path}"
    echo ""
    echo "Available tasks:"
    echo "  rake push       # git auto commit and push (kk-git)"
    echo "  rake run        # docker compose up"
    echo "  ruby push.rb    # editor / Code Runner shortcut"
}

# run main
krun::config::rakefile::run "$@"
