# Krun 快捷命令清单

复制即用（curl / irm）。

刷新本页：`rake docs:commands`

## 部署 CLI

安装 / **覆盖更新** / 卸载。重复执行安装会写回已有路径并清其它残留。

### Linux / macOS

```bash
# 安装或覆盖更新到最新 Release
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/deploy.sh | bash
# 钉版本
KRUN_VERSION=v2.2.0 curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/deploy.sh | bash
# 卸载
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/deploy.sh | bash -s -- --uninstall
```

### Windows

```powershell
# 安装或覆盖更新到最新 Release
irm https://raw.githubusercontent.com/kevin197011/krun/main/deploy.ps1 | iex
# 钉版本
$env:KRUN_VERSION='v2.2.0'; irm https://raw.githubusercontent.com/kevin197011/krun/main/deploy.ps1 | iex
# 卸载
$env:KRUN_ACTION='uninstall'; irm https://raw.githubusercontent.com/kevin197011/krun/main/deploy.ps1 | iex
```

## Shell（Linux / macOS）

通用：

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/<name>.sh | sudo bash
```

### 安装

#### `install_1panel.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_1panel.sh | sudo bash
```

#### `install_aapanel.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_aapanel.sh | sudo bash
```

#### `install_aliyun_cli.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_aliyun_cli.sh | sudo bash
```

#### `install_ansible.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_ansible.sh | sudo bash
```

#### `install_asdf.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_asdf.sh | sudo bash
```

#### `install_awscli.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_awscli.sh | sudo bash
```

#### `install_base_packages.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_base_packages.sh | sudo bash
```

#### `install_blackbox_exporter.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_blackbox_exporter.sh | sudo bash
```

#### `install_cpanm.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_cpanm.sh | sudo bash
```

#### `install_crane.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_crane.sh | sudo bash
```

#### `install_cursor_cli.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_cursor_cli.sh | sudo bash
```

#### `install_devbox.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_devbox.sh | sudo bash
```

#### `install_docker.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_docker.sh | sudo bash
```

#### `install_elixir.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_elixir.sh | sudo bash
```

#### `install_ffmpeg.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_ffmpeg.sh | sudo bash
```

#### `install_filebeat.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_filebeat.sh | sudo bash
```

#### `install_fonts_nerd_jetbrains.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_fonts_nerd_jetbrains.sh | sudo bash
```

#### `install_gcloud.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_gcloud.sh | sudo bash
```

#### `install_geoipupdate.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_geoipupdate.sh | sudo bash
```

#### `install_git.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_git.sh | sudo bash
```

#### `install_golang.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_golang.sh | sudo bash
```

#### `install_helm.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_helm.sh | sudo bash
```

#### `install_jdk8.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_jdk8.sh | sudo bash
```

#### `install_k9s.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_k9s.sh | sudo bash
```

#### `install_kind.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_kind.sh | sudo bash
```

#### `install_kssh.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_kssh.sh | sudo bash
```

#### `install_lsyncd.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_lsyncd.sh | sudo bash
```

#### `install_maven.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_maven.sh | sudo bash
```

#### `install_mc.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_mc.sh | sudo bash
```

#### `install_mysql.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_mysql.sh | sudo bash
```

#### `install_nexttrace.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_nexttrace.sh | sudo bash
```

#### `install_nginx.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_nginx.sh | sudo bash
```

#### `install_node_exporter.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_node_exporter.sh | sudo bash
```

#### `install_node_exporter_offline.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_node_exporter_offline.sh | sudo bash
```

#### `install_oh_my_zsh.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_oh_my_zsh.sh | sudo bash
```

#### `install_openjdk.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_openjdk.sh | sudo bash
```

#### `install_percona_toolkit.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_percona_toolkit.sh | sudo bash
```

#### `install_puppet_bolt.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_puppet_bolt.sh | sudo bash
```

#### `install_python3.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_python3.sh | sudo bash
```

#### `install_rbenv.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_rbenv.sh | sudo bash
```

#### `install_rclone.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_rclone.sh | sudo bash
```

#### `install_redis.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_redis.sh | sudo bash
```

#### `install_ruby.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_ruby.sh | sudo bash
```

#### `install_salt_master.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_salt_master.sh | sudo bash
```

#### `install_salt_minion.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_salt_minion.sh | sudo bash
```

#### `install_spacevim.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_spacevim.sh | sudo bash
```

#### `install_tinyproxy.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_tinyproxy.sh | sudo bash
```

#### `install_vagrant_virtualbox.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_vagrant_virtualbox.sh | sudo bash
```

#### `install_vim.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_vim.sh | sudo bash
```

#### `install_zsh.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_zsh.sh | sudo bash
```

### 配置

#### `config_acme.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_acme.sh | sudo bash
```

#### `config_centos7_repo.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_centos7_repo.sh | sudo bash
```

#### `config_cursor.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_cursor.sh | sudo bash
```

#### `config_disk_data.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_disk_data.sh | sudo bash
```

#### `config_elasticsearch.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_elasticsearch.sh | sudo bash
```

#### `config_fstab.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_fstab.sh | sudo bash
```

#### `config_git.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_git.sh | sudo bash
```

#### `config_jumpserver_ssh_timeout.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_jumpserver_ssh_timeout.sh | sudo bash
```

#### `config_locales.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_locales.sh | sudo bash
```

#### `config_proxy.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_proxy.sh | sudo bash
```

#### `config_rakefile.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_rakefile.sh | sudo bash
```

#### `config_rocky_repo.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_rocky_repo.sh | sudo bash
```

#### `config_rpm_repo.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_rpm_repo.sh | sudo bash
```

#### `config_ruby_http.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_ruby_http.sh | sudo bash
```

#### `config_ssh.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_ssh.sh | sudo bash
```

#### `config_ssh_authorized_keys.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_ssh_authorized_keys.sh | sudo bash
```

#### `config_system_baseline.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_system_baseline.sh | sudo bash
```

#### `config_timezone.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_timezone.sh | sudo bash
```

#### `config_vagrant_ssh.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_vagrant_ssh.sh | sudo bash
```

#### `config_vm.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/config_vm.sh | sudo bash
```

### 检查

#### `check_ip_quality.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/check_ip_quality.sh | sudo bash
```

#### `check_system_baseline.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/check_system_baseline.sh | sudo bash
```

#### `check_system_troubleshoot.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/check_system_troubleshoot.sh | sudo bash
```

### 部署

#### `deploy_node_exporter.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/deploy_node_exporter.sh | sudo bash
```

#### `deploy_sshkey.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/deploy_sshkey.sh | sudo bash
```

### 其它

#### `apply_asdf.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/apply_asdf.sh | sudo bash
```

#### `crane_copy.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/crane_copy.sh | sudo bash
```

#### `delete_video.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/delete_video.sh | sudo bash
```

#### `disable_firewall_selinux.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/disable_firewall_selinux.sh | sudo bash
```

#### `disk_cleanup.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/disk_cleanup.sh | sudo bash
```

#### `hello_world.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/hello_world.sh | sudo bash
```

#### `init_system.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/init_system.sh | sudo bash
```

#### `reset_git_history.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/reset_git_history.sh | sudo bash
```

#### `update_vagrant_box.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/update_vagrant_box.sh | sudo bash
```

## PowerShell（Windows）

通用（管理员）：

```powershell
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/<name>.ps1 | iex
```

强制重装：`$env:FORCE_INSTALL='true'` 或 `-Force`。

### 安装

#### `install_bandizip.ps1`

```powershell
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_bandizip.ps1 | iex
```

#### `install_caddy.ps1`

```powershell
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_caddy.ps1 | iex
```

#### `install_chrome.ps1`

```powershell
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_chrome.ps1 | iex
```

#### `install_cursor.ps1`

```powershell
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_cursor.ps1 | iex
```

#### `install_obs.ps1`

```powershell
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_obs.ps1 | iex
```

#### `install_snipaste.ps1`

```powershell
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_snipaste.ps1 | iex
```

#### `install_vscode.ps1`

```powershell
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_vscode.ps1 | iex
```

#### `install_windows_all.ps1`

```powershell
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_windows_all.ps1 | iex
```

#### `install_winget.ps1`

```powershell
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_winget.ps1 | iex
```

### 配置

#### `config_remote.ps1`

```powershell
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/config_remote.ps1 | iex
```

#### `config_timezone_utc8_ntp.ps1`

```powershell
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/config_timezone_utc8_ntp.ps1 | iex
```

#### `disable_firewall.ps1`

```powershell
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

