# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

require 'net/http'
require 'uri'

count_sn = 'CN'
cache_file = 'apnic.txt'

unless File.exist?(cache_file) || File.size?(cache_file)
  uri = URI.parse('https://ftp.apnic.net/stats/apnic/delegated-apnic-latest')
  request = Net::HTTP::Get.new(uri)
  req_options = { use_ssl: uri.scheme == 'https' }
  response =
    Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
  File.write(cache_file, response.body)
end

pattern = /apnic\|#{count_sn}\|ipv4\|(?<ip>\d+\.\d+\.\d+\.\d+)\|(?<hosts>\d+)\|\d+\|allocated/mi

File.readlines(cache_file).select do |line|
  next unless line.match(pattern)

  val = line.match(pattern)
  netmask = 32 - Math.log2(val[:hosts].to_i).to_i
  puts "#{val[:ip]}/#{netmask}"
end
