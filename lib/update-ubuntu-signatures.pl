# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

@repositories_release_keys = qw(
  http://download.opensuse.org/repositories/home:/Provessor/xUbuntu_20.04/Release.key
  http://download.opensuse.org/repositories/home:/Provessor/xUbuntu_20.04/Release.key
  http://download.opensuse.org/repositories/shells:/zsh-users:/zsh-completions/xUbuntu_19.10/Release.key
);

foreach(@repositories_release_keys) {
  print "update $_ signatures ...";
  system "wget -qO - '$_' | apt-key --keyring /etc/apt/trusted.gpg add -";
}

print "all updated!"