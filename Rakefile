# frozen_string_literal: true

# Copyright (c) 2025 kk
# MIT License: https://opensource.org/licenses/MIT

require 'json'
require 'fileutils'
require 'bundler/setup'
require 'kk/git/rake_tasks'

task default: %w[push]

task :push do
  Rake::Task['lib:manifest'].invoke
  Rake::Task['git:auto_commit_push'].invoke
end

MANIFEST_DIR = 'meta'
MANIFEST_PATH = File.join(MANIFEST_DIR, 'lib-manifest.json')

namespace :lib do
  desc 'Generate meta/lib-manifest.json from lib/ contents'
  task :manifest do
    files = Dir['lib/*'].select { |f| File.file?(f) }.map { |f| File.basename(f) }.sort
    FileUtils.mkdir_p(MANIFEST_DIR)
    File.write(MANIFEST_PATH, JSON.pretty_generate({ 'files' => files }))
    puts "Wrote #{MANIFEST_PATH} (#{files.size} files)"
  end
end
