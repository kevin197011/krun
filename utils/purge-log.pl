# Copyright (c) 2023 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

use File::Find;

my @files;
my @filepath=qw(/www/);

sub find_match_file {
  push @files, $File::Find::name if (-f $File::Find::name and /.*\.log$/);
}

find \&find_match_file, @filepath;

unlink @files;

