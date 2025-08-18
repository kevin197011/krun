# frozen_string_literal: true

# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

require 'erb'
require 'time'
require 'rake'
require 'json'

task default: %w[push]

task :push do
  Rake::Task[:shfmt].invoke
  Rake::Task[:generate_json].invoke
  system 'git add .'
  system "git commit -m 'Update #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}.'"
  system 'git pull'
  system 'git push origin main'
end

task :new do
  print 'action: '
  action = $stdin.gets.strip
  print 'name: '
  name = $stdin.gets.strip

  script_name = "#{__dir__}/lib/#{action}-#{name}.sh"
  File.rename(script_name, "#{script_name}.bak") if File.exist?(script_name)

  template = File.read("#{__dir__}/templates/bash.sh.erb")
  File.write(script_name, ERB.new(template, trim_mode: '-').result(binding))
  puts "Created #{action}-#{name}.sh!"
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
  puts "Shell scripts: #{scripts.length}"
  puts "Total lines: #{scripts.sum { |f| File.readlines(f).length }}"
end
