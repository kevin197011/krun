# frozen_string_literal: true

# Copyright (c) 2025 kk
# MIT License: https://opensource.org/licenses/MIT

require 'erb'
require 'time'
require 'rake'
require 'json'
require 'fileutils'

task default: %w[push]

task :push do
  Rake::Task[:shfmt].invoke
  Rake::Task[:generate_json].invoke
  system 'git add .'
  system "git commit -m 'Update #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}'"
  system 'git pull'
  system 'git push origin main'
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

def prompt(name)
  print "#{name}: "
  $stdin.gets.strip
end
