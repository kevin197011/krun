# Krun - 运维自动化脚本工具集

```
______
___  /____________  ________
__  //_/_  ___/  / / /_  __ \
_  ,<  _  /   / /_/ /_  / / /
/_/|_| /_/    \__,_/ /_/ /_/
       Ops Script Runner
```

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-2.1-blue.svg)](https://github.com/kevin197011/krun)
[![Scripts](https://img.shields.io/badge/scripts-170+-green.svg)](https://github.com/kevin197011/krun/tree/main/lib)

## 项目简介

Krun 是一个面向运维工程师的脚本工具集，提供 **Shell**、**Python** 与 **PowerShell** 三类运维脚本，覆盖系统初始化、安全加固、服务部署、性能优化以及 Windows 装机配置等场景。支持 CentOS/RHEL、Debian/Ubuntu、macOS、Windows，可通过 curl / `irm | iex` 直接执行。

### 目录结构

```
krun/
├── bin/krun                 # CLI 运行器
├── meta/lib-manifest.json   # 脚本清单
├── lib/
│   ├── sh/
│   │   ├── *.sh                 # 独立完整 bash 实现（与 py 同名）
│   │   ├── install_python3.sh   # 无 Python 时 bootstrap
│   │   └── install_node_exporter_offline.sh  # 离线安装
│   ├── ps1/
│   │   └── *.ps1                # Windows PowerShell 安装/配置
│   └── py/
│       └── scripts/             # 独立完整 Python 脚本（与 sh/ps1 同风格）
└── install.sh               # 安装 krun CLI
```

### 项目架构

```mermaid
flowchart TB
    subgraph User["用户"]
        CLI["krun install_docker.py"]
        CURL["curl .../scripts/xxx.py | python3"]
    end

    subgraph Runner["运行层"]
        KRUN["bin/krun"]
        PY3["python3"]
        BASH["bash"]
        PS1["pwsh"]
    end

    subgraph Scripts["脚本层（各自完整实现）"]
        SH["lib/sh/*.sh"]
        PY["lib/py/scripts/*.py"]
        PS["lib/ps1/*.ps1"]
    end

    CLI --> KRUN
    KRUN --> SH
    KRUN --> PY
    KRUN --> PS
    CURL --> PY3 --> PY
```

### 调用流程

**方式 A：krun CLI**

```mermaid
sequenceDiagram
    actor U as 用户
    participant K as bin/krun
    participant M as meta/lib-manifest.json
    participant S as lib/py/scripts/xxx.py

    U->>K: krun install_docker.py
    K->>M: 解析脚本名
    K->>S: python3 直接执行该文件
    S-->>U: 完成
```

**方式 B：curl 管道**

```mermaid
sequenceDiagram
    actor U as 用户
    participant S as scripts/xxx.py

    U->>S: curl | sudo python3
    Note over S: 单文件完整脚本，仅标准库
    S-->>U: 完成
```

**开发者新增脚本**

```mermaid
flowchart LR
    A["手写或套模版"] --> B["lib/sh|py/scripts|ps1"]
    B --> C["rake lib:manifest"]
    C --> D["krun list 可见"]
```


### 核心特性

- 🚀 **一键安装**: 170+ 运维脚本，按语言分目录管理（sh / py / ps1）
- 🔧 **系统配置**: 完善的系统初始化和安全加固脚本
- 🌐 **多平台支持**: CentOS/RHEL 7-9、Debian/Ubuntu、macOS、Windows
- 📦 **模块化设计**: 每个脚本独立运行，可单独使用或组合使用
- 🔒 **安全可靠**: MIT 许可证，所有脚本开源可审查
- 🎯 **远程执行**: 支持 curl 直接执行，无需克隆仓库
- ⚡ **自动依赖**: 安装脚本自动检测并安装所需依赖（Python3、curl 等）
- 🐚 **Shell 脚本**: `lib/sh/*.sh`，通过 bash 执行
- 🐍 **Python 脚本**: `lib/py/scripts/*.py`，通过 python3 执行
- 💠 **PowerShell 脚本**: `lib/ps1/*.ps1`，通过 pwsh/powershell 执行（Windows）

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

### Windows 装机与远程
- **软件安装**: winget、Chrome、Bandizip、Snipaste、OBS、Caddy、VS Code（`lib/ps1/install_*.ps1`）
- **系统配置**: 东八区 NTP、关闭防火墙、RDP + WinRM 远程服务
- **批量安装**: `install_windows_all.ps1`（读 manifest `ps1` 列表）

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

# 执行脚本（自动下载并执行；sh/py 同名，各自独立实现）
krun install_docker.py
krun install_docker.sh      # 完整 bash，不调用 Python
krun init_system.py
krun install_python3.sh     # 无 python3 时 bootstrap
```

**安装说明**：
- 支持 macOS 和 Linux（CentOS/RHEL、Debian/Ubuntu）
- 自动检测平台并安装所需依赖（Python3、curl）
- 自动配置 PATH 环境变量
- 安装目录：`~/.krun/bin/krun`
- `lib/sh` 与 `lib/py` 各自完整实现，互不委托；命名同 stem，仅扩展名不同
- 本地开发时 `krun` 优先读仓库内文件，再回退 GitHub raw

### 方式二：直接执行脚本

```bash
# Docker 安装
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/scripts/install_docker.py | sudo python3

# FFmpeg 安装
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/scripts/install_ffmpeg.py | sudo python3

# Rocky Linux 仓库配置
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/scripts/config_rocky_repo.py | sudo python3

# 系统初始化与性能优化
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/scripts/init_system.py | sudo python3

# Python3 依赖安装（唯一 shell 脚本）
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/sh/install_python3.sh | bash
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
./lib/py/scripts/install_docker.py
./lib/py/scripts/init_system.py

# 方式 3.3: 使用本地 krun 工具
./bin/krun install_git.py
```

## 脚本列表

以 `meta/lib-manifest.json` 为准（当前约 **177**：sh 84 + py 82 + ps1 11）。命名统一 `snake_case`：

```bash
krun list
# 或
cat meta/lib-manifest.json
```

主要分类：

| 类别 | 示例 |
|------|------|
| 系统初始化 | `init_system.py`, `config_system_baseline.py`, `disable_firewall_selinux.py` |
| 软件源/磁盘 | `config_rocky_repo.py`, `config_disk_data.py`, `disk_cleanup.py` |
| 安装类 | `install_docker.py`, `install_nginx.py`, `install_golang.py`, `install_nexttrace.py` |
| 运维工具 | `deploy_node_exporter.py`, `crane_copy.py`, `check_ip_quality.py` |
| 开发环境 | `install_asdf.py`, `install_oh_my_zsh.py`, `install_rbenv.py` |
| Windows | `install_chrome.ps1`, `config_remote.ps1`, `disable_firewall.ps1` |

- `lib/sh/`：独立完整 bash（不调用 Python）；与 `lib/py/scripts/*.py` 同名对应
- `lib/ps1/`：Windows PowerShell；与 Linux 脚本独立，不互相委托

## Windows（PowerShell）

原独立仓 **windows-utils** 能力已并入本仓 `lib/ps1/`（原仓废弃，请只使用 krun）。需求权威：[`docs/REQUIREMENTS.md`](docs/REQUIREMENTS.md)；目录说明：[`lib/ps1/README.md`](lib/ps1/README.md)。

| 脚本 | 说明 |
|------|------|
| `install_winget.ps1` | 安装/升级 winget |
| `install_chrome.ps1` | Google Chrome |
| `install_bandizip.ps1` | Bandizip |
| `install_snipaste.ps1` | Snipaste（便携） |
| `install_obs.ps1` | OBS Studio |
| `install_caddy.ps1` | Caddy |
| `install_vscode.ps1` | VS Code System Installer |
| `install_windows_all.ps1` | 按 manifest 批量跑 `install_*.ps1` |
| `config_timezone_utc8_ntp.ps1` | 东八区 + NTP |
| `disable_firewall.ps1` | 关闭全部防火墙配置文件 |
| `config_remote.ps1` | 全自动 RDP + WinRM；防火墙开着才加规则，全关则跳过 |

```powershell
# 单脚本（远程）
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_chrome.ps1 | iex

# 强制重装
$env:FORCE_INSTALL='true'; irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_vscode.ps1 | iex

# 批量安装
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_windows_all.ps1 | iex

# 远程服务 + 关防火墙（按需）
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/config_remote.ps1 | iex
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/disable_firewall.ps1 | iex
```

本机已装 `krun` 且有 `pwsh`/`powershell`：`krun install_chrome.ps1` / `krun config_remote.ps1`。

## 支持平台

- **CentOS/RHEL**: 7, 8, 9
- **Rocky Linux**: 8, 9
- **AlmaLinux**: 8, 9
- **Debian**: 10, 11, 12
- **Ubuntu**: 18.04, 20.04, 22.04, 24.04
- **macOS**: 10.15+ (部分脚本)
- **Windows**: 10/11 / Server（`lib/ps1`，需 PowerShell；部分需管理员）

## 使用示例

### 新服务器初始化

```bash
# 1. 安装 krun 工具
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/install.sh | bash
source ~/.bashrc

# 2. 系统基础配置
krun disable_firewall_selinux.py
krun config_system_baseline.py
krun config_ssh.py
krun init_system.py

# 3. 安装常用软件
krun install_docker.py
krun install_git.py
krun install_vim.py

# 4. 配置开发环境
krun install_python3.sh
krun install_golang.py
krun install_oh_my_zsh.py
```

### Rocky Linux 9 修复 IPv6 源问题

```bash
# 修复 Rocky Linux 9 的 IPv6 源导致的包管理器问题
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/py/scripts/config_rocky_repo.py | sudo python3
```

### Kubernetes 环境搭建

```bash
krun install_docker.py
krun install_kind.py
krun install_helm.py
krun install_k9s.py
```

### 自动挂载数据盘

```bash
# 自动格式化并挂载数据盘到 /data
data_disk="/dev/sdb" mount_point="/data" sudo python3 lib/py/scripts/config_disk_data.py
```

## 注意事项

1. **权限要求**: 大部分脚本需要 root 或 sudo 权限执行
2. **备份重要**: 脚本会自动备份原始配置文件到 `.bak` 或 `backup/` 目录
3. **网络要求**: 需要稳定的网络连接下载软件包
4. **测试环境**: 建议先在测试环境验证脚本功能
5. **安全审查**: 执行前请审查脚本内容，确保符合安全要求
6. **平台兼容**: 部分脚本仅支持特定平台，请查看脚本说明

## 开发者指南

### Python 脚本

`lib/py/scripts/*.py` 与 Shell/PowerShell 一样：**一文件完整实现**（平台分支 + 业务逻辑）。无 registry/handlers/bootstrap。说明见 [`lib/py/README.md`](lib/py/README.md)。

### 创建新脚本

```bash
# Python：从 templates/python.py.erb 生成 lib/py/scripts/<action>_<name>.py，填 common()
# Shell：lib/sh/<action>_<name>.sh（完整 bash）
# PowerShell：templates/powershell.ps1.erb → lib/ps1/<action>_<name>.ps1
# 最后刷新清单：
rake lib:manifest
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

### Q: curl 执行 Python 脚本报错？
每个 `lib/py/scripts/*.py` 已是独立脚本（仅标准库）。请确认：
1. URL 指向 `lib/py/scripts/<name>.py`
2. 使用 `python3`（多数脚本需 `sudo`）
3. 网络可访问 `raw.githubusercontent.com`

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
ls -l lib/sh/*.sh lib/py/scripts/*.py
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
**更新时间**: 2026-11-11
**脚本数量**: 170+
**支持平台**: CentOS/RHEL 7-9、Debian/Ubuntu、macOS、Windows

**Star ⭐ 支持项目发展！**