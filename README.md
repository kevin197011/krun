# krun

> scripts manage tools

## support script language

- shell
- perl
- ruby
- python

## install

```bash
export deploy_path='/root/.krun' && \
sh -c "$(curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/deploy.sh)"
```

## init

```bash
[root@localhost ~]# krun status (krun init)
[INFO] krun ready!
```

## custom yourself script repo

new create `sh-libs` repo.

```bash
[root@localhost ~]# vim /etc/krun/config.py
github_repo_name = "kevin197011" # your repo github name
```

example

```bash
https://github.com/kevin197011/sh-libs
```

## show script list

```bash
[root@localhost ~]# krun list
[INFO] script list:
  - [1]config-acme.sh
  - [2]config-fstab.sh
  - [3]config-locales.sh
  - [4]config-ssh.sh
  - [5]config-system.sh
  - [6]config-vagrant-ssh.sh
  - [7]config-vim.sh
  - [8]config-vm.sh
  - [9]db-sync.sh
  - [10]deploy-node_exporter.sh
  - [11]hello-world.sh
  - [12]install-1panel.sh
  - [13]install-aapanel.sh
  - [14]install-asdf.sh
  - [15]install-awscli.sh
  - [16]install-docker.sh
  - [17]install-golang.sh
  - [18]install-k9s.sh
  - [19]install-kssh.sh
  - [20]install-nginx.sh
  - [21]install-openjdk8.sh
  - [22]install-puppet_bolt.sh
  - [23]install-python3.sh
  - [24]install-ruby.sh
  - [25]install-vagrant-virtualbox.sh
  - [26]install-xtrabackup.sh
```

## run script

> run script name

```bash
[root@localhost ~]# krun hello-world.sh
hello world
```

> run script No.

```bash
[root@localhost ~]# krun 11
hello world
```

## update

```bash
[root@localhost ~]# krun update
[INFO] krun update!
```

## uninstall

```bash
[root@localhost ~]# krun uninstall
[INFO] krun uninstall!
```
