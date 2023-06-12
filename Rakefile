# frozen_string_literal: true

# Copyright (c) 2022 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

require 'erb'

task default: [:run]

task :run do
  sh 'git add .'
  sh 'git commit -m "update."'
  sh 'git push -u origin main'
end

task :new do
  print 'action: '
  @action = $stdin.gets.strip
  print 'name: '
  @name = $stdin.gets.strip
  File.open("#{File.dirname(__FILE__)}/lib/#{@action}-#{@name}.sh", 'w') do |f|
    tpl = File.read("#{File.dirname(__FILE__)}/templates/bash.sh.erb")
    f.write(ERB.new(tpl, trim_mode: '-').result(binding))
    puts "Create #{@action}-#{@name}.sh!"
  end
end
