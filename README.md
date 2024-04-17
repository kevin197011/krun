# krun

> scripts manage tools

## support script language

- shell
- perl
- ruby
- python

## install krun

```bash
# export deploy_path="/root/.krun"  # custom deploy path
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/deploy.sh | bash
```

## list script

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
  - [8]hello-world.sh
  ...
```

## run script

> run script No.

```bash
[root@localhost ~]# krun 8
hello world
```

> run script name

```bash
[root@localhost ~]# krun hello-world.sh
hello world
```