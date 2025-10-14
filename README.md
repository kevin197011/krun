# Krun - 运维自动化脚本工具集

```
______
___  /____________  ________
__  //_/_  ___/  / / /_  __ \
_  ,<  _  /   / /_/ /_  / / /
/_/|_| /_/    \__,_/ /_/ /_/
       Multi-Language Script Runner
```

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-2.0-blue.svg)](https://github.com/kevin197011/krun)

## 项目简介

Krun 是一个面向运维工程师的自动化脚本工具集，提供了系统初始化、安全加固、服务部署、性能优化等常用运维脚本。支持 CentOS/RHEL、Debian/Ubuntu、macOS 等多个平台，可通过 curl 命令直接执行，简化运维工作流程。

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

### 直接执行脚本
```bash
# 系统基线安全配置
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-system-baseline.sh | bash

# 安装基础软件包
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-base-packages.sh | bash

# 系统性能优化
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/optimize-system-performance.sh | bash

# Docker 安装
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-docker.sh | bash
```

### 本地使用
```bash
# 克隆仓库
git clone https://github.com/kevin197011/krun.git
cd krun

# 执行脚本
./lib/config-system-baseline.sh
./lib/install-base-packages.sh
```

## 脚本列表

### 系统配置类
- `config-system-baseline.sh` - 系统安全基线配置
- `config-system.sh` - 系统基础配置
- `config-ssh.sh` - SSH 安全配置
- `config-locales.sh` - 系统语言环境配置
- `config-vim.sh` - Vim 编辑器配置
- `optimize-system-performance.sh` - 系统性能优化

### 软件安装类
- `install-base-packages.sh` - 基础软件包安装
- `install-docker.sh` - Docker 容器平台安装
- `install-python3.sh` - Python 3 环境安装
- `install-golang.sh` - Go 语言环境安装
- `install-nodejs.sh` - Node.js 环境安装
- `install-ruby.sh` - Ruby 环境安装

### 数据库类
- `install-mysql.sh` - MySQL 数据库安装
- `install-postgresql.sh` - PostgreSQL 数据库安装
- `install-redis.sh` - Redis 缓存安装
- `install-mongodb.sh` - MongoDB 数据库安装

### 运维工具类
- `install-node_exporter.sh` - Prometheus 监控安装
- `delete-video.sh` - 视频文件清理脚本
- `config-centos7_repo.sh` - CentOS 7 软件源配置
- `config-rocky-repo.sh` - Rocky Linux 软件源配置

## 支持平台

- **CentOS/RHEL**: 7, 8, 9
- **Rocky Linux**: 8, 9
- **AlmaLinux**: 8, 9
- **Debian**: 10, 11, 12
- **Ubuntu**: 18.04, 20.04, 22.04, 24.04
- **macOS**: 10.15+ (部分脚本)

## 注意事项

1. **权限要求**: 大部分脚本需要 root 权限执行
2. **备份重要**: 脚本会自动备份原始配置文件
3. **网络要求**: 需要稳定的网络连接下载软件包
4. **测试环境**: 建议先在测试环境验证脚本功能
5. **安全审查**: 执行前请审查脚本内容，确保符合安全要求

## 贡献指南

欢迎提交 Issue 和 Pull Request 来改进项目：

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/new-script`)
3. 提交更改 (`git commit -am 'Add new script'`)
4. 推送到分支 (`git push origin feature/new-script`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证，详情请查看 [LICENSE](LICENSE) 文件。

---

**项目地址**: https://github.com/kevin197011/krun  
**作者**: [kevin197011](https://github.com/kevin197011)  
**更新时间**: 2024-12-14