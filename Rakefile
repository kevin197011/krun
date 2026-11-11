# frozen_string_literal: true

# Copyright (c) 2025 kk
# MIT License: https://opensource.org/licenses/MIT

require 'bundler/setup'
require 'shellwords'
require 'kk/git/rake_tasks'

task default: %w[push]

desc 'Build Go CLI into bin/krun'
task :build do
  sh 'mkdir -p bin'
  sh 'go build -ldflags "-s -w -X main.version=dev -X main.commit=local" -o bin/krun ./cmd/krun'
end

desc 'Commit + push, then bump and push a new v* tag (triggers Release)'
task :push do
  # kk-git defaults to `git pull --ff-only`, which fails on diverged branches.
  ENV['KK_GIT_PULL_ARGS'] ||= '--no-rebase'

  head_before = `git rev-parse HEAD`.strip

  generator = lambda do
    Rake::Task['git:auto_commit'].reenable
    Rake::Task['git:auto_commit'].invoke
    ENV.fetch('KK_GIT_COMMIT_MESSAGE', '').to_s
  end

  result = KKGit::GitOps.auto_commit_push!(commit_message_generator: generator)
  head_after = `git rev-parse HEAD`.strip

  if ENV['SKIP_TAG'] == '1'
    puts 'SKIP_TAG=1 — not tagging'
    next
  end

  # Tag only when this push produced a new commit (叠加版本).
  unless result == :committed_and_synced || head_before != head_after
    puts "No new commit (#{result}) — skip tag"
    next
  end

  tag = next_semver_tag
  msg = "Release #{tag}"
  sh "git tag -a #{Shellwords.escape(tag)} -m #{Shellwords.escape(msg)}"
  sh "git push #{Shellwords.escape(KKGit::GitOps.remote)} #{Shellwords.escape(tag)}"
  puts "Tagged and pushed #{tag}"
end

def next_semver_tag
  bump = (ENV['KRUN_BUMP'] || 'patch').downcase
  unless %w[major minor patch].include?(bump)
    abort "KRUN_BUMP must be major|minor|patch (got #{bump})"
  end

  tags = `git tag -l 'v*'`.split("\n").filter_map do |t|
    m = t.match(/\Av(\d+)\.(\d+)\.(\d+)\z/)
    next unless m

    [m[1].to_i, m[2].to_i, m[3].to_i]
  end
  major, minor, patch = tags.max || [1, 0, 0]

  case bump
  when 'major'
    major += 1
    minor = 0
    patch = 0
  when 'minor'
    minor += 1
    patch = 0
  else
    patch += 1
  end

  format('v%d.%d.%d', major, minor, patch)
end
