# frozen_string_literal: true

# Copyright (c) 2025 kk
# MIT License: https://opensource.org/licenses/MIT

require 'bundler/setup'
require 'json'
require 'fileutils'
require 'kk/git/rake_tasks'

task default: %w[push]

task :push do
  Rake::Task['lib:manifest'].invoke
  # kk-git defaults to `git pull --ff-only`, which fails on diverged branches.
  ENV['KK_GIT_PULL_ARGS'] ||= '--no-rebase'
  Rake::Task['git:auto_commit_push'].invoke
end

MANIFEST_DIR = 'meta'
MANIFEST_PATH = File.join(MANIFEST_DIR, 'lib-manifest.json')

namespace :lib do
  desc 'Generate meta/lib-manifest.json from lib/sh and lib/py'
  task :manifest do
    sh_files = Dir['lib/sh/*'].select { |f| File.file?(f) }.map { |f| File.basename(f) }.sort
    py_files = Dir['lib/py/scripts/*.py'].select { |f| File.file?(f) }.map { |f| File.basename(f) }.sort
    FileUtils.mkdir_p(MANIFEST_DIR)
    File.write(MANIFEST_PATH, JSON.pretty_generate({ 'sh' => sh_files, 'py' => py_files.sort }))
    puts "Wrote #{MANIFEST_PATH} (sh: #{sh_files.size}, py: #{py_files.size})"
  end

  desc 'Regenerate lib/py entrypoints from registry'
  task 'py:generate' do
    system('python3', 'lib/py/generate_wrappers.py') || raise('generate failed')
    ver = `git rev-parse --short HEAD 2>/dev/null`.strip
    ver = Time.now.utc.strftime('%Y%m%d%H%M') if ver.empty?
    File.write('lib/py/krun/VERSION', "#{ver}\n")
    puts "Wrote lib/py/krun/VERSION (#{ver})"
    Rake::Task['lib:manifest'].invoke
  end
end
