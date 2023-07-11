# frozen_string_literal: true

# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

require 'erb'
require 'time'

task default: [:run]

task :run do
  sh 'git add .'
  # sh 'aicommits'
  sh 'git commit -m "update."'
  sh 'git push -u origin main'
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
