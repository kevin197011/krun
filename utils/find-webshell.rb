# frozen_string_literal: true

# Copyright (c) 2023 Kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# gem install colorize

require 'colorize'

def match_str(base_name, php_func, file_type)
  puts("Include #{php_func} Files:".red)
  Dir["#{base_name}/**/*#{file_type}"].each do |f|
    File.open(f, 'r:utf-8') do |lines|
      next unless lines.read.include?(php_func)

      puts(f)
    end
  rescue StandardError => e
    puts("File #{f} error! => #{e.message}")
  end
end

strs = %w[
  base64_decode(
  eval(
  assert(
  system(
  exec(
  shell_exec(
  passthru(
  pcntl_exec(
  popen(
  proc_open(
  chroot(
  chgrp(
  chown(
  ini_alter(
  ini_restore(
  dl(
  openlog(
  syslog(
  readlink(
  symlink(
  popepassthru(
  pcntl_alarm(
  pcntl_fork(
  pcntl_waitpid(
  pcntl_wait(
  pcntl_wifexited(
  pcntl_wifstopped(
  pcntl_wifsignaled(
  pcntl_wifcontinued(
  pcntl_wexitstatus(
  pcntl_wtermsig(
  pcntl_wstopsig(
  pcntl_signal(
  pcntl_signal_dispatch(
  pcntl_get_last_error(
  pcntl_strerror(
  pcntl_sigprocmask(
  pcntl_sigwaitinfo(
  pcntl_sigtimedwait(
  pcntl_getpriority(
  pcntl_setpriority(
  imap_open(
  apache_setenv(
]

# base_name = File.dirname(__FILE__)
base_name = '/www/wwwroot'

file_type = '.php'
# match_str(base_name, str, file_type)

strs.each do |str|
  match_str(base_name, str, file_type)
end
