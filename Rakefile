# frozen_string_literal: true

# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

require 'erb'
require 'time'
require 'rake'
require 'json'

task default: %w[shfmt push]

task :push do
  Rake::Task[:shfmt].invoke
  Rake::Task[:generate_json].invoke
  system 'git add .'
  system "git commit -m 'Update #{Time.now}.'"
  system 'git pull'
  system 'git push origin main'
end

task :new do
  @year = Time.now.year
  print 'action: '
  @action = $stdin.gets.strip
  print 'name: '
  @name = $stdin.gets.strip
  script_name = "#{File.dirname(__FILE__)}/lib/#{@action}-#{@name}.sh"
  File.rename(script_name, "#{script_name}.bak") if File.exist?(script_name)
  File.open(script_name, 'w') do |f|
    tpl = File.read("#{File.dirname(__FILE__)}/templates/bash.sh.erb")
    f.write(ERB.new(tpl, trim_mode: '-').result(binding))
    puts "Create #{@action}-#{@name}.sh!"
  end
end

task :shfmt do
  system 'shfmt -i 4 -w -d . || true'
end

task :generate_json do
  fs = Dir.glob("#{__dir__}/lib/*.sh").map { |f| File.basename(f) }
  File.open("#{__dir__}/resources/krun.json", 'w') do |f|
    f.write(fs.to_json)
  end
end
