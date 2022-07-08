# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

@files = glob('/www/wwwroot/**/*.user.ini');

foreach( @files ) {
  print "chattr -i $_\n";
  system "chattr -i $_";
}