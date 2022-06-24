# sh
sh

## 安装部署
```bash
curl -o /usr/bin/krun https://raw.githubusercontent.com/kevin197011/sh/main/krun && chmod +x /usr/bin/krun
```
## 部署完成检查状态
```bash
[root@localhost ~]# krun status
[INFO] krun ready!
```
## 需要自定义仓库[非必要配置项]
在自己的github新建仓库`sh-libs`, 然后讲自己的脚本上传到自己的仓库。
完成上步然后配置自己的仓库地址
```bash
[root@localhost ~]# vim /etc/krun/config.sh
github_repo_name="kevin197011" # 填写自己的github name
```
## 查看脚本清单
```bash
[root@localhost ~]# krun list
- hello-world.sh
- install-cfssl.pl
- install-ruby.sh
- set-vim-paste-mode.sh
```

## 执行脚本
```bash
[root@localhost ~]# krun hello-world.sh
hello world
```

## 更新krun版本
```bash
[root@localhost ~]# krun update
[INFO] krun update!
```
