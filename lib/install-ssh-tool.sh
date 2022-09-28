# Copyright (c) 2022 kk
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

tee /usr/bin/kssh > /dev/null <<EOF

#!/usr/bin/env ruby
# Copyright (c) 2022 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

opts = ARGV

# default key path
default_key_path = '~/.ssh'

# config host list
kssh_hosts = [
  { 'name': 'devops-node1', 'ip': '1.2.3.1', 'username': 'root', 'method': 'key', 'passwdOrKey': 'id_rsa' },
  { 'name': 'devops-node2', 'ip': '1.2.3.2', 'username': 'root', 'method': 'key', 'passwdOrKey': 'id_rsa' },
  { 'name': 'devops-node3', 'ip': '1.2.3.3', 'username': 'root', 'method': 'key', 'passwdOrKey': 'id_rsa' },
]

unless opts.length >= 1
  print "Usage: \n  kssh [list|host[number]]!"
  exit(true)
end
if opts.first == 'list'
  puts 'Hosts List:'
  kssh_hosts.each_with_index do |value, index|
    index += 1
    puts "[#{index}]#{value[:name]} => #{value[:ip]}"
  end
  exit(true)
end

num = opts.first
val = kssh_hosts[num.to_i - 1]
system("ssh -i #{default_key_path}/#{val[:passwdOrKey]} #{val[:username]}@#{val[:ip]}")
EOF

chmod +x /usr/bin/kssh
