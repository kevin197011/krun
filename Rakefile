# frozen_string_literal: true

# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

task default: [:run]

task :run do
  sh 'git add .'
  sh 'git commit -m "update."'
  sh 'git push -u origin main'
end

task :new do
  print 'action: '
  @action = gets.strip
  print 'name: '
  @name = gets.strip

  # File.open("#{File.dirname(__FILE__)}/lib/#{@action}-#{@name}.rb", 'w') do |f|
  #   tpl = File.read("#{File.dirname(__FILE__)}/templates/bash.sh.erb")
  #   f.write(ERB.new(tpl, trim_mode: '-').result(binding))
  # end
end
