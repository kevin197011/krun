# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# git push
# system 'rake'

# require 'tty-command'
# require 'rake'

# cmd = TTY::Command.new
Dir.chdir('sh') do
  # cmd.run(:rake)
  system 'rake'
end
