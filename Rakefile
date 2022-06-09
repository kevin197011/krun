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
