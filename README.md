# Krun - 运维自动化脚本工具集

```
______
___  /____________  ________
__  //_/_  ___/  / / /_  __ \
_  ,<  _  /   / /_/ /_  / / /
/_/|_| /_/    \__,_/ /_/ /_/
       Shell Script Runner
```

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-2.0-blue.svg)](https://github.com/kevin197011/krun)
[![Scripts](https://img.shields.io/badge/scripts-66+-green.svg)](https://github.com/kevin197011/krun/tree/main/lib)

## 项目简介

Krun 是一个面向运维工程师的 Shell 脚本工具集，提供了 **66+ 个**系统初始化、安全加固、服务部署、性能优化等常用运维脚本。支持 CentOS/RHEL、Debian/Ubuntu、macOS 等多个平台，可通过 curl 命令直接执行，简化运维工作流程。

### 核心特性

- 🚀 **一键安装**: 支持 66+ 个常用软件和工具的自动化安装
- 🔧 **系统配置**: 完善的系统初始化和安全加固脚本
- 🌐 **多平台支持**: CentOS/RHEL 7-9、Debian/Ubuntu、macOS
- 📦 **模块化设计**: 每个脚本独立运行，可单独使用或组合使用
- 🔒 **安全可靠**: MIT 许可证，所有脚本开源可审查
- 🎯 **远程执行**: 支持 curl 直接执行，无需克隆仓库
- ⚡ **自动依赖**: 安装脚本自动检测并安装所需依赖（Python3、curl 等）
- 🐚 **Shell 脚本**: 所有脚本使用 Bash，简单可靠

## 主要功能

### 系统配置
- **系统基线配置**: 安全加固、内核参数优化、SSH配置
- **软件源配置**: CentOS 7/Rocky Linux 软件源配置
- **基础软件安装**: 常用运维工具包安装
- **系统性能优化**: 内核参数、网络、存储性能调优

### 服务部署
- **容器服务**: Docker 安装配置
- **开发环境**: Python、Node.js、Go、Ruby 环境安装
- **数据库**: MySQL、PostgreSQL、Redis、MongoDB 部署
- **Web服务**: Nginx、Apache 配置

### 运维工具
- **监控工具**: Node Exporter、系统监控脚本
- **日志管理**: 日志轮转、清理脚本
- **备份工具**: 数据备份、配置备份脚本
- **网络工具**: 网络诊断、性能测试工具

## 快速开始

### 方式一：安装 Krun 工具（推荐）

```bash
# 一键安装（自动检测平台并安装依赖）
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/install.sh | bash

# 重新加载 shell 配置
source ~/.bashrc  # 或 source ~/.zshrc

# 查看可用脚本列表
krun list

# 执行脚本（自动下载并执行）
krun install-docker.sh
krun init-system.sh
krun install-ffmpeg.sh
```

**安装说明**：
- 支持 macOS 和 Linux（CentOS/RHEL、Debian/Ubuntu）
- 自动检测平台并安装所需依赖（Python3、curl）
- 自动配置 PATH 环境变量
- 安装目录：`~/.krun/bin/krun`
- krun 工具用于管理 shell 脚本，所有脚本通过 bash 执行

### 方式二：直接执行脚本

```bash
# Docker 安装
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-docker.sh | bash

# FFmpeg 安装
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-ffmpeg.sh | bash

# Rocky Linux 仓库配置（修复 IPv6 问题）
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-rocky-repo.sh | bash

# 系统初始化与性能优化
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/init-system.sh | bash
```

### 方式三：本地使用

```bash
# 克隆仓库
git clone https://github.com/kevin197011/krun.git
cd krun

# 方式 3.1: 使用安装脚本安装 krun 工具
./install.sh
source ~/.bashrc  # 或 source ~/.zshrc
krun list

# 方式 3.2: 直接执行脚本
./lib/install-docker.sh
./lib/init-system.sh

# 方式 3.3: 使用本地 krun 工具
./bin/krun install-git.sh
```

## 脚本列表（66+ 个）

### 📋 系统配置类（17个）
- `config-system-baseline.sh` - 系统安全基线配置
- `init-system.sh` - 新机器系统初始化（软件包、内核调优、limits）
- `config-ssh.sh` - SSH 安全配置
- `config-locales.sh` - 系统语言环境配置
- `config-git.sh` - Git 全局配置
- `config-vim.sh` - Vim 编辑器配置
- `config-fstab.sh` - 文件系统挂载配置
- `config-disk-data.sh` - 数据盘自动挂载配置
- `config-vm.sh` - 虚拟机初始化配置
- `config-acme.sh` - ACME 证书配置
- `config-elasticsearch.sh` - Elasticsearch 配置
- `config-rakefile.sh` - Rakefile 自动生成
- `config-cursor.sh` - Cursor 配置部署
- `config-centos7-repo.sh` - CentOS 7 软件源配置
- `config-rocky-repo.sh` - Rocky Linux 软件源配置（修复 IPv6）
- `disable-firewall-selinux.sh` - 关闭防火墙和 SELinux

### 🚀 开发环境安装类（20个）
- `install-git.sh` - Git 版本控制工具
- `install-vim.sh` - Vim 编辑器
- `install-docker.sh` - Docker 容器平台
- `install-python3.sh` - Python 3 环境
- `install-golang.sh` - Go 语言环境
- `install-ruby.sh` - Ruby 语言环境
- `install-elixir.sh` - Elixir 语言环境
- `install-openjdk.sh` - OpenJDK Java 环境
- `install-maven.sh` - Maven 构建工具
- `install-rbenv.sh` - Ruby 版本管理器
- `install-asdf.sh` - 多语言版本管理器
- `install-oh_my_zsh.sh` - Oh My Zsh 终端配置
- `install-zsh.sh` - Zsh Shell
- `install-spacevim.sh` - SpaceVim 配置
- `install-fonts-nerd-JetBrainsMono.sh` - JetBrains Mono Nerd Font 字体
- `install-fonts-powerline.sh` - Powerline 字体
- `install-awscli.sh` - AWS CLI 工具
- `install-gcloud.sh` - Google Cloud CLI
- `install-aliyun-cli.sh` - 阿里云 CLI 工具
- `install-devbox.sh` - Devbox 开发环境

### 🔧 运维工具安装类（15个）
- `install-node_exporter.sh` - Prometheus Node Exporter
- `install-helm.sh` - Kubernetes Helm 包管理器
- `install-k9s.sh` - Kubernetes TUI 管理工具
- `install-kind.sh` - Kubernetes in Docker
- `install-kssh.sh` - Kubernetes SSH 工具
- `install-nginx.sh` - Nginx Web 服务器
- `install-redis.sh` - Redis 缓存数据库
- `install-mc.sh` - MinIO Client 对象存储客户端
- `install-lsyncd.sh` - 文件同步工具
- `install-tinyproxy.sh` - 轻量级代理服务器
- `install-percona_toolkit.sh` - MySQL 工具集
- `install-puppet_bolt.sh` - Puppet Bolt 自动化工具
- `install-vagrant-virtualbox.sh` - Vagrant + VirtualBox 虚拟化
- `install-geoipupdate.sh` - GeoIP 数据库更新工具
- `install-ffmpeg.sh` - FFmpeg 多媒体处理工具

### 🎛️ 面板和管理工具（2个）
- `install-1panel.sh` - 1Panel 服务器管理面板
- `install-aapanel.sh` - aaPanel 服务器管理面板

### 🛠️ 运维脚本类（8个）
- `deploy-node_exporter.sh` - 批量部署 Node Exporter
- `deploy-sshkey.sh` - 批量部署 SSH 密钥
- `delete-video.sh` - 视频文件清理脚本
- `db-sync.sh` - 数据库同步脚本
- `get-host_info.sh` - 获取主机信息
- `get-ipaddr.sh` - 获取 IP 地址信息
- `check-ip.sh` - IP 地址检查工具
- `update-vagrant_box.sh` - 更新 Vagrant Box

### 🔄 Git 工具类（2个）
- `reset-git-history.sh` - 重置 Git 提交历史
- `apply-asdf.sh` - 应用 ASDF 配置

### 📝 其他工具（3个）
- `hello-world.sh` - 示例脚本
- `config-vagrant-ssh.sh` - Vagrant SSH 配置
- `config-ruby-http.sh` - Ruby HTTP 配置

## 支持平台

- **CentOS/RHEL**: 7, 8, 9
- **Rocky Linux**: 8, 9
- **AlmaLinux**: 8, 9
- **Debian**: 10, 11, 12
- **Ubuntu**: 18.04, 20.04, 22.04, 24.04
- **macOS**: 10.15+ (部分脚本)

## 使用示例

### 新服务器初始化

```bash
# 1. 安装 krun 工具
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/install.sh | bash
source ~/.bashrc

# 2. 系统基础配置
krun disable-firewall-selinux.sh
krun config-system-baseline.sh
krun config-ssh.sh
krun init-system.sh

# 3. 安装常用软件
krun install-docker.sh
krun install-git.sh
krun install-vim.sh

# 4. 配置开发环境
krun install-python3.sh
krun install-golang.sh
krun install-oh_my_zsh.sh
```

### Rocky Linux 9 修复 IPv6 源问题

```bash
# 修复 Rocky Linux 9 的 IPv6 源导致的包管理器问题
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-rocky-repo.sh | bash
```

### Kubernetes 环境搭建

```bash
krun install-docker.sh
krun install-kind.sh
krun install-helm.sh
krun install-k9s.sh
```

### 自动挂载数据盘

```bash
# 自动格式化并挂载数据盘到 /data
data_disk="/dev/sdb" mount_point="/data" bash lib/config-disk-data.sh
```

## 注意事项

1. **权限要求**: 大部分脚本需要 root 或 sudo 权限执行
2. **备份重要**: 脚本会自动备份原始配置文件到 `.bak` 或 `backup/` 目录
3. **网络要求**: 需要稳定的网络连接下载软件包
4. **测试环境**: 建议先在测试环境验证脚本功能
5. **安全审查**: 执行前请审查脚本内容，确保符合安全要求
6. **平台兼容**: 部分脚本仅支持特定平台，请查看脚本说明

## 开发者指南

### 脚本标准格式

所有脚本使用 Bash，遵循统一格式（参考 `lib/hello-world.sh`）：

- 使用 `set -o errexit`, `set -o nounset`, `set -o pipefail`
- 函数命名：`krun::category::scriptname::function`
- 平台检测：自动识别 debian/centos/mac
- 统一入口：通过 `run()` 函数调用

### 创建新脚本

```bash
# 参考模板创建
cp lib/hello-world.sh lib/install-myapp.sh
# 修改函数名和实现逻辑
```

## 贡献指南

欢迎提交 Issue 和 Pull Request 来改进项目：

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/new-script`)
3. 按照标准格式编写脚本
4. 测试脚本在不同平台的兼容性
5. 提交更改 (`git commit -am 'Add new script'`)
6. 推送到分支 (`git push origin feature/new-script`)
7. 创建 Pull Request

## 常见问题

### Q: 如何更新 krun 工具？
```bash
# 重新运行安装脚本即可（会自动下载最新版本）
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/install.sh | bash
source ~/.bashrc  # 或 source ~/.zshrc
```

### Q: 如何查看所有可用脚本？
```bash
# 使用 krun 工具查看脚本列表
krun list

# 或直接查看 lib 目录
ls -l lib/*.sh
```

### Q: 脚本执行失败怎么办？
1. 检查是否有 root/sudo 权限
2. 检查网络连接是否正常
3. 查看错误日志，定位具体问题
4. 提交 Issue 描述问题和环境信息

### Q: 如何卸载 krun？
```bash
# 删除安装目录
rm -rf ~/.krun

# 删除 PATH 配置
# 编辑 ~/.bashrc 或 ~/.zshrc，删除 krun 相关的 PATH 配置
```

### Q: 安装脚本会自动安装依赖吗？
```bash
# 是的，install.sh 会自动检测并安装所需依赖：
# - macOS: 使用 Homebrew 安装 Python3 和 curl（如未安装 Homebrew 会自动安装）
# - Linux: 使用系统包管理器（apt/yum/dnf）安装 Python3 和 curl
# 如果系统已有这些依赖，则跳过安装步骤
```

## 许可证

本项目采用 MIT 许可证，详情请查看 [LICENSE](LICENSE) 文件。

## 相关资源

- 📚 [项目文档](https://github.com/kevin197011/krun/wiki)
- 💬 [问题反馈](https://github.com/kevin197011/krun/issues)
- 🔄 [更新日志](https://github.com/kevin197011/krun/releases)
- 🌟 [脚本示例](https://github.com/kevin197011/krun/tree/main/examples)

---

**项目地址**: https://github.com/kevin197011/krun
**作者**: [kevin197011](https://github.com/kevin197011)
**更新时间**: 2025-12-04
**脚本数量**: 66+
**支持平台**: CentOS/RHEL 7-9、Debian/Ubuntu、macOS

**Star ⭐ 支持项目发展！**