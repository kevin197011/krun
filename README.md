# krun

> 脚本管理执行工具[托管github]

## 支持托管执行脚本类型
- shell
- perl
- ruby
- python

## 安装部署
```bash
curl -o /usr/bin/krun https://raw.githubusercontent.com/kevin197011/krun/main/krun && chmod +x /usr/bin/krun && krun status
```
## 部署完成检查状态
```bash
[root@localhost ~]# krun status (krun init)
[INFO] krun ready!
```
## 需要自定义仓库[非必要配置项]
在自己的github新建仓库`sh-libs`, 然后将自己的脚本上传到自己的仓库。
完成上步然后配置自己的仓库地址
```bash
[root@localhost ~]# vim /etc/krun/config.py
github_repo_name = "kevin197011" # 填写自己的github name
```
范例
```bash
https://github.com/kevin197011/sh-libs
```

## 查看脚本清单
```bash
[root@localhost ~]# krun list
[INFO] script list:
- [1]config-acme.sh
- [2]config-centos7.sh
- [3]config-ssh.sh
- [4]config-vagrant.sh
- [5]delete-log-in-crontab.sh
- [6]find-chattr.pl
- [7]find-log-delete.sh
- [8]find-webshell.rb
- [9]get-apnic.rb
- [10]hello-world.sh
- [11]install-aapanel.sh
- [12]install-cfssl.pl
- [13]install-docker.sh
- [14]install-maven.sh
- [15]install-openjdk8.sh
- [16]install-python3.sh
- [17]install-ruby.sh
- [18]install-vagrant-vbox.sh
- [19]purge-log.pl
- [20]set-vim-paste-mode.sh
- [21]update-ubuntu-signatures.pl
- [22]webhook.py
```

## 执行脚本

> 根据脚本名字执行
```bash
[root@localhost ~]# krun hello-world.sh
hello world
```

> 根据脚本编号执行
```bash
[root@localhost ~]# krun 10
hello world
```

## 更新krun版本
```bash
[root@localhost ~]# krun update
[INFO] krun update!
```

## 卸载工具
```bash
[root@localhost ~]# krun uninstall
[INFO] krun uninstall!
```
