# Krun 快捷命令清单

复制即用。脚本已 `go:embed` 进 CLI；也可 curl/irm 单文件执行。

刷新本页：`rake docs:commands`

## 安装 CLI

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/install.sh | bash
```

```bash
krun list
krun languages
krun version
```

## Shell（Linux / macOS）

通用：

```bash
krun <name>.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/<name>.sh | sudo bash
```

### 安装

#### `install_1panel.sh`

```bash
krun install_1panel.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_1panel.sh | sudo bash
```

#### `install_aapanel.sh`

```bash
krun install_aapanel.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_aapanel.sh | sudo bash
```

#### `install_aliyun_cli.sh`

```bash
krun install_aliyun_cli.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_aliyun_cli.sh | sudo bash
```

#### `install_ansible.sh`

```bash
krun install_ansible.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_ansible.sh | sudo bash
```

#### `install_asdf.sh`

```bash
krun install_asdf.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_asdf.sh | sudo bash
```

#### `install_awscli.sh`

```bash
krun install_awscli.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_awscli.sh | sudo bash
```

#### `install_base_packages.sh`

```bash
krun install_base_packages.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_base_packages.sh | sudo bash
```

#### `install_blackbox_exporter.sh`

```bash
krun install_blackbox_exporter.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_blackbox_exporter.sh | sudo bash
```

#### `install_cpanm.sh`

```bash
krun install_cpanm.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_cpanm.sh | sudo bash
```

#### `install_crane.sh`

```bash
krun install_crane.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_crane.sh | sudo bash
```

#### `install_cursor_cli.sh`

```bash
krun install_cursor_cli.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_cursor_cli.sh | sudo bash
```

#### `install_devbox.sh`

```bash
krun install_devbox.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_devbox.sh | sudo bash
```

#### `install_docker.sh`

```bash
krun install_docker.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_docker.sh | sudo bash
```

#### `install_elixir.sh`

```bash
krun install_elixir.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_elixir.sh | sudo bash
```

#### `install_ffmpeg.sh`

```bash
krun install_ffmpeg.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_ffmpeg.sh | sudo bash
```

#### `install_filebeat.sh`

```bash
krun install_filebeat.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_filebeat.sh | sudo bash
```

#### `install_fonts_nerd_jetbrains.sh`

```bash
krun install_fonts_nerd_jetbrains.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_fonts_nerd_jetbrains.sh | sudo bash
```

#### `install_gcloud.sh`

```bash
krun install_gcloud.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_gcloud.sh | sudo bash
```

#### `install_geoipupdate.sh`

```bash
krun install_geoipupdate.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_geoipupdate.sh | sudo bash
```

#### `install_git.sh`

```bash
krun install_git.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_git.sh | sudo bash
```

#### `install_golang.sh`

```bash
krun install_golang.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_golang.sh | sudo bash
```

#### `install_helm.sh`

```bash
krun install_helm.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_helm.sh | sudo bash
```

#### `install_jdk8.sh`

```bash
krun install_jdk8.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_jdk8.sh | sudo bash
```

#### `install_k9s.sh`

```bash
krun install_k9s.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_k9s.sh | sudo bash
```

#### `install_kind.sh`

```bash
krun install_kind.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_kind.sh | sudo bash
```

#### `install_kssh.sh`

```bash
krun install_kssh.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_kssh.sh | sudo bash
```

#### `install_lsyncd.sh`

```bash
krun install_lsyncd.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_lsyncd.sh | sudo bash
```

#### `install_maven.sh`

```bash
krun install_maven.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_maven.sh | sudo bash
```

#### `install_mc.sh`

```bash
krun install_mc.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_mc.sh | sudo bash
```

#### `install_mysql.sh`

```bash
krun install_mysql.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_mysql.sh | sudo bash
```

#### `install_nexttrace.sh`

```bash
krun install_nexttrace.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_nexttrace.sh | sudo bash
```

#### `install_nginx.sh`

```bash
krun install_nginx.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_nginx.sh | sudo bash
```

#### `install_node_exporter.sh`

```bash
krun install_node_exporter.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_node_exporter.sh | sudo bash
```

#### `install_node_exporter_offline.sh`

```bash
krun install_node_exporter_offline.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_node_exporter_offline.sh | sudo bash
```

#### `install_oh_my_zsh.sh`

```bash
krun install_oh_my_zsh.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_oh_my_zsh.sh | sudo bash
```

#### `install_openjdk.sh`

```bash
krun install_openjdk.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_openjdk.sh | sudo bash
```

#### `install_percona_toolkit.sh`

```bash
krun install_percona_toolkit.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_percona_toolkit.sh | sudo bash
```

#### `install_puppet_bolt.sh`

```bash
krun install_puppet_bolt.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_puppet_bolt.sh | sudo bash
```

#### `install_python3.sh`

```bash
krun install_python3.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_python3.sh | sudo bash
```

#### `install_rbenv.sh`

```bash
krun install_rbenv.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_rbenv.sh | sudo bash
```

#### `install_rclone.sh`

```bash
krun install_rclone.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_rclone.sh | sudo bash
```

#### `install_redis.sh`

```bash
krun install_redis.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_redis.sh | sudo bash
```

#### `install_ruby.sh`

```bash
krun install_ruby.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_ruby.sh | sudo bash
```

#### `install_salt_master.sh`

```bash
krun install_salt_master.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_salt_master.sh | sudo bash
```

#### `install_salt_minion.sh`

```bash
krun install_salt_minion.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_salt_minion.sh | sudo bash
```

#### `install_spacevim.sh`

```bash
krun install_spacevim.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_spacevim.sh | sudo bash
```

#### `install_tinyproxy.sh`

```bash
krun install_tinyproxy.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_tinyproxy.sh | sudo bash
```

#### `install_vagrant_virtualbox.sh`

```bash
krun install_vagrant_virtualbox.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_vagrant_virtualbox.sh | sudo bash
```

#### `install_vim.sh`

```bash
krun install_vim.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_vim.sh | sudo bash
```

#### `install_zsh.sh`

```bash
krun install_zsh.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_zsh.sh | sudo bash
```

### 配置

#### `config_acme.sh`

```bash
krun config_acme.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_acme.sh | sudo bash
```

#### `config_centos7_repo.sh`

```bash
krun config_centos7_repo.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_centos7_repo.sh | sudo bash
```

#### `config_cursor.sh`

```bash
krun config_cursor.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_cursor.sh | sudo bash
```

#### `config_disk_data.sh`

```bash
krun config_disk_data.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_disk_data.sh | sudo bash
```

#### `config_elasticsearch.sh`

```bash
krun config_elasticsearch.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_elasticsearch.sh | sudo bash
```

#### `config_fstab.sh`

```bash
krun config_fstab.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_fstab.sh | sudo bash
```

#### `config_git.sh`

```bash
krun config_git.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_git.sh | sudo bash
```

#### `config_jumpserver_ssh_timeout.sh`

```bash
krun config_jumpserver_ssh_timeout.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_jumpserver_ssh_timeout.sh | sudo bash
```

#### `config_locales.sh`

```bash
krun config_locales.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_locales.sh | sudo bash
```

#### `config_proxy.sh`

```bash
krun config_proxy.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_proxy.sh | sudo bash
```

#### `config_rakefile.sh`

```bash
krun config_rakefile.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_rakefile.sh | sudo bash
```

#### `config_rocky_repo.sh`

```bash
krun config_rocky_repo.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_rocky_repo.sh | sudo bash
```

#### `config_rpm_repo.sh`

```bash
krun config_rpm_repo.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_rpm_repo.sh | sudo bash
```

#### `config_ruby_http.sh`

```bash
krun config_ruby_http.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_ruby_http.sh | sudo bash
```

#### `config_ssh.sh`

```bash
krun config_ssh.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_ssh.sh | sudo bash
```

#### `config_ssh_authorized_keys.sh`

```bash
krun config_ssh_authorized_keys.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_ssh_authorized_keys.sh | sudo bash
```

#### `config_system_baseline.sh`

```bash
krun config_system_baseline.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_system_baseline.sh | sudo bash
```

#### `config_timezone.sh`

```bash
krun config_timezone.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_timezone.sh | sudo bash
```

#### `config_vagrant_ssh.sh`

```bash
krun config_vagrant_ssh.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_vagrant_ssh.sh | sudo bash
```

#### `config_vm.sh`

```bash
krun config_vm.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_vm.sh | sudo bash
```

### 检查

#### `check_ip_quality.sh`

```bash
krun check_ip_quality.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/check_ip_quality.sh | sudo bash
```

#### `check_system_baseline.sh`

```bash
krun check_system_baseline.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/check_system_baseline.sh | sudo bash
```

#### `check_system_troubleshoot.sh`

```bash
krun check_system_troubleshoot.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/check_system_troubleshoot.sh | sudo bash
```

### 部署

#### `deploy_node_exporter.sh`

```bash
krun deploy_node_exporter.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/deploy_node_exporter.sh | sudo bash
```

#### `deploy_sshkey.sh`

```bash
krun deploy_sshkey.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/deploy_sshkey.sh | sudo bash
```

### 其它

#### `apply_asdf.sh`

```bash
krun apply_asdf.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/apply_asdf.sh | sudo bash
```

#### `crane_copy.sh`

```bash
krun crane_copy.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/crane_copy.sh | sudo bash
```

#### `delete_video.sh`

```bash
krun delete_video.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/delete_video.sh | sudo bash
```

#### `disable_firewall_selinux.sh`

```bash
krun disable_firewall_selinux.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/disable_firewall_selinux.sh | sudo bash
```

#### `disk_cleanup.sh`

```bash
krun disk_cleanup.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/disk_cleanup.sh | sudo bash
```

#### `hello_world.sh`

```bash
krun hello_world.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/hello_world.sh | sudo bash
```

#### `init_system.sh`

```bash
krun init_system.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/init_system.sh | sudo bash
```

#### `reset_git_history.sh`

```bash
krun reset_git_history.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/reset_git_history.sh | sudo bash
```

#### `update_vagrant_box.sh`

```bash
krun update_vagrant_box.sh
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/update_vagrant_box.sh | sudo bash
```

## PowerShell（Windows）

通用（管理员）：

```powershell
krun <name>.ps1
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/<name>.ps1 | iex
```

强制重装：`$env:FORCE_INSTALL='true'` 或 `-Force`。

### 安装

#### `install_bandizip.ps1`

```powershell
krun install_bandizip.ps1
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_bandizip.ps1 | iex
```

#### `install_caddy.ps1`

```powershell
krun install_caddy.ps1
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_caddy.ps1 | iex
```

#### `install_chrome.ps1`

```powershell
krun install_chrome.ps1
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_chrome.ps1 | iex
```

#### `install_obs.ps1`

```powershell
krun install_obs.ps1
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_obs.ps1 | iex
```

#### `install_snipaste.ps1`

```powershell
krun install_snipaste.ps1
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_snipaste.ps1 | iex
```

#### `install_vscode.ps1`

```powershell
krun install_vscode.ps1
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_vscode.ps1 | iex
```

#### `install_windows_all.ps1`

```powershell
krun install_windows_all.ps1
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_windows_all.ps1 | iex
```

#### `install_winget.ps1`

```powershell
krun install_winget.ps1
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_winget.ps1 | iex
```

### 配置

#### `config_remote.ps1`

```powershell
krun config_remote.ps1
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/config_remote.ps1 | iex
```

#### `config_timezone_utc8_ntp.ps1`

```powershell
krun config_timezone_utc8_ntp.ps1
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/config_timezone_utc8_ntp.ps1 | iex
```

#### `disable_firewall.ps1`

```powershell
krun disable_firewall.ps1
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/disable_firewall.ps1 | iex
```

## 发布

```bash
ruby push.rb                 # 提交 + 推送 + 自动 v* tag（patch+1）
KRUN_BUMP=minor ruby push.rb
SKIP_TAG=1 ruby push.rb
rake build                   # 本地编译 bin/krun
rake docs:commands           # 刷新本清单
```

