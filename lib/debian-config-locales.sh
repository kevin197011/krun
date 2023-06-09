krun::debian::config::locales() {
  apt-get clean -y
  apt-get update -y
  apt-get install locales -y
  grep -q 'LC_ALL=en_US.UTF-8' /etc/environment || echo "LC_ALL=en_US.UTF-8" >>/etc/environment
  grep -q 'en_US.UTF-8 UTF-8' /etc/locale.gen || echo "en_US.UTF-8 UTF-8" >>/etc/locale.gen
  echo "LANG=en_US.UTF-8" >/etc/locale.conf
  locale-gen en_US.UTF-8
  export LC_ALL="en_US.UTF-8"
  dpkg-reconfigure locales
}

exec krun::config::debian_locales "$@"
