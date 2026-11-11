# frozen_string_literal: true

# Copyright (c) 2025 kk
# MIT License: https://opensource.org/licenses/MIT

require 'bundler/setup'
require 'kk/git/rake_tasks'

task default: %w[push]

desc 'Build Go CLI into bin/krun'
task :build do
  sh 'mkdir -p bin'
  sh 'go build -ldflags "-s -w -X main.version=dev -X main.commit=local" -o bin/krun ./cmd/krun'
end

task :push do
  # kk-git defaults to `git pull --ff-only`, which fails on diverged branches.
  ENV['KK_GIT_PULL_ARGS'] ||= '--no-rebase'
  Rake::Task['git:auto_commit_push'].invoke
end
