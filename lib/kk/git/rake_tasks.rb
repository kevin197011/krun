#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

require 'rake'
require 'time'

namespace :git do
  desc 'Auto add/commit/pull/push (non-interactive)'
  task :auto_commit_push do
    unless system('git rev-parse --is-inside-work-tree >/dev/null 2>&1')
      warn '✗ Not a git repository'
      exit 1
    end

    system('git add .') || exit(1)

    # Only commit when there are staged changes
    if system('git diff --cached --quiet')
      puts '✓ No changes to commit'
    else
      msg = "chore: update #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
      system("git commit -m #{msg.inspect}") || exit(1)
      puts "✓ Committed: #{msg}"
    end

    # Keep it simple and safe
    system('git pull --rebase') || exit(1)
    system('git push origin HEAD') || exit(1)
    puts '✓ Pushed'
  end
end

