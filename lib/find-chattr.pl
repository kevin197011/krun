# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# @files = glob('/www/wwwroot/**/*.user.ini');

# foreach( @files ) {
#   print "chattr -i $_\n";
#   system "chattr -i $_";
# }


use File::Find;

my @files;
my @filepath=qw(/www/wwwroot/);

sub find_match_file {
  push @files, $File::Find::name if (-f $File::Find::name and /^\.user\.ini$/);
}

find(\&find_match_file, @filepath);

foreach( @files ) {
  print "chattr -i $_\n";
  system "chattr -i $_";
}
