# frozen_string_literal: true

# Copyright (c) 2025 kk
# MIT License: https://opensource.org/licenses/MIT

require 'erb'
require 'time'
require 'rake'
require 'json'
require 'fileutils'
require 'bundler/setup'
lib_dir = File.join(__dir__, 'lib')
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)
require 'kk/git/rake_tasks'

task default: %w[push]

task :push do
  # Rake::Task[:shfmt].invoke
  Rake::Task[:generate_json].invoke
  Rake::Task['git:auto_commit_push'].invoke
end

task :new do
  action = prompt('action')
  name = prompt('name')
  script_path = "#{__dir__}/lib/#{action}-#{name}.sh"

  File.rename(script_path, "#{script_path}.bak") if File.exist?(script_path)

  template = File.read("#{__dir__}/templates/bash.sh.erb")
  content = ERB.new(template, trim_mode: '-').result(binding)

  File.write(script_path, content)
  FileUtils.chmod(0o755, script_path)
  puts "✓ Created #{action}-#{name}.sh"
end

task :shfmt do
  system 'shfmt -i 4 -w -d . || true'
end

task :generate_json do
  scripts = Dir.glob("#{__dir__}/lib/*.sh").map { |f| File.basename(f) }.sort
  File.write("#{__dir__}/resources/krun.json", JSON.pretty_generate(scripts))
end

task :clean do
  Dir.glob("#{__dir__}/lib/*.bak").each { |f| File.delete(f) }
  puts 'Cleaned backup files'
end

task :stats do
  scripts = Dir.glob("#{__dir__}/lib/*.sh")
  total_lines = scripts.sum { |f| File.readlines(f).length }

  puts "Scripts: #{scripts.length} | Lines: #{total_lines} | Avg: #{total_lines / scripts.length}"

  scripts.map { |f| [f, File.mtime(f)] }
         .sort_by { |_, mtime| -mtime.to_i }
         .first(5)
         .each { |file, mtime| puts "  #{File.basename(file).ljust(30)} #{mtime.strftime('%Y-%m-%d %H:%M')}" }
end

task :tag do
  version = prompt('version (e.g., 2.0.0)')
  tag = "v#{version}"

  # Check if tag already exists
  if system("git rev-parse #{tag} >/dev/null 2>&1")
    puts "✗ Tag #{tag} already exists"
    exit 1
  end

  # Create and push tag
  system "git tag -a #{tag} -m 'Release #{tag}'"
  system "git push origin #{tag}"

  puts "✓ Created and pushed tag #{tag}"
  puts "  GitHub Actions will automatically build and release packages"
end

def prompt(name)
  print "#{name}: "
  $stdin.gets.strip
end
