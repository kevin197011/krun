# frozen_string_literal: true

require 'time'

system 'git add .'
system "git commit -m \"Update #{Time.now}.\""
system 'git pull'
system 'git push'
