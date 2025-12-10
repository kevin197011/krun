# Project Context

## Purpose
Krun 是一个面向运维工程师的自动化脚本工具集，提供了 66+ 个系统初始化、安全加固、服务部署、性能优化等常用运维脚本。支持 CentOS/RHEL、Debian/Ubuntu、macOS 等多个平台，可通过 curl 命令直接执行，简化运维工作流程。

## Tech Stack
- **主要语言**: Bash Shell Scripts
- **包管理**: 使用系统包管理器（yum/dnf/apt/brew）
- **版本控制**: Git
- **项目管理**: Rake (Ruby)
- **代码质量**: Rubocop

## Project Conventions

### Code Style
所有脚本必须遵循以下标准格式（参考 `lib/hello-world.sh`）：

```bash
#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/script-name.sh | bash

# vars

# run code
krun::category::scriptname::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::category::scriptname::centos() {
    krun::category::scriptname::common
}

# debian code
krun::category::scriptname::debian() {
    krun::category::scriptname::common
}

# mac code
krun::category::scriptname::mac() {
    krun::category::scriptname::common
}

# common code
krun::category::scriptname::common() {
    # Implementation here
}

# run main
krun::category::scriptname::run "$@"
```

**关键规范**:
- 必须包含 MIT 许可证头
- 使用 `set -o errexit`, `set -o nounset`, `set -o pipefail` 确保错误处理
- 函数命名使用 `krun::category::scriptname::function` 格式
- 平台检测统一使用相同的逻辑
- 简化输出，避免过多的颜色和 emoji
- 所有新文件必须包含 MIT 许可证头

### Architecture Patterns
- **模块化设计**: 每个脚本独立运行，可单独使用或组合使用
- **多平台支持**: 通过平台检测自动选择对应的安装/配置逻辑
- **统一入口**: 所有脚本通过 `run()` 函数作为入口点
- **错误处理**: 使用 `set -o errexit` 确保错误时立即退出
- **权限检查**: Linux 脚本需要 root 权限时进行明确检查

### Testing Strategy
- 脚本应在目标平台上进行实际测试
- 使用 `bash -n script.sh` 进行语法检查
- 在测试环境验证后再部署到生产环境
- 重要脚本应包含回滚机制

### Git Workflow
遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

**Commit Message 格式**:
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type 类型**:
- `feat`: 新功能
- `fix`: 修复bug
- `docs`: 文档变更
- `style`: 代码格式（不影响代码运行）
- `refactor`: 重构（既不是新增功能，也不是修复bug）
- `perf`: 性能优化
- `test`: 增加测试
- `chore`: 构建过程或辅助工具的变动

**示例**:
```
feat(nginx): add simplified installation script

Simplify nginx installation to use default configuration only.
Remove complex custom configurations and keep core functionality.

Closes #123
```

## Domain Context

### 脚本分类
1. **系统配置类** (17个): 系统安全基线、SSH配置、软件源配置等
2. **开发环境安装类** (20个): Git、Docker、Python、Go、Ruby 等
3. **运维工具安装类** (15个): Nginx、Redis、Node Exporter、Helm 等
4. **面板和管理工具** (2个): 1Panel、aaPanel
5. **运维脚本类** (8个): 批量部署、数据同步、IP检查等
6. **其他工具** (4个): 示例脚本、配置脚本等

### 平台支持
- **CentOS/RHEL**: 7, 8, 9
- **Rocky Linux**: 8, 9
- **AlmaLinux**: 8, 9
- **Debian**: 10, 11, 12
- **Ubuntu**: 18.04, 20.04, 22.04, 24.04
- **macOS**: 10.15+ (部分脚本)

### 脚本命名规范
- **安装脚本**: `install-{tool}.sh` (如 `install-docker.sh`)
- **配置脚本**: `config-{feature}.sh` (如 `config-ssh.sh`)
- **部署脚本**: `deploy-{service}.sh` (如 `deploy-node_exporter.sh`)
- **工具脚本**: `{action}-{target}.sh` (如 `check-ip.sh`, `get-ipaddr.sh`)

## Important Constraints

1. **权限要求**: 大部分脚本需要 root 或 sudo 权限执行
2. **网络要求**: 需要稳定的网络连接下载软件包
3. **防火墙和 SELinux**: 默认假设防火墙和 SELinux 已关闭（使用 `disable-firewall-selinux.sh` 脚本）
4. **向后兼容**: 修改现有脚本时保持向后兼容，避免破坏性变更
5. **简洁优先**: 优先使用系统默认配置，避免过度定制

## External Dependencies

- **GitHub**: 脚本通过 GitHub 托管，支持 curl 直接执行
- **系统包管理器**: yum/dnf (RHEL系列), apt (Debian系列), brew (macOS)
- **官方软件源**: 优先使用官方软件源（如 nginx.org, docker.com）
- **GitHub Releases**: 部分工具从 GitHub Releases 下载二进制文件

## 维护状态

### 当前版本
- **版本**: 2.0
- **脚本数量**: 66+
- **最后更新**: 2025-12-04

### 活跃维护
- ✅ 项目处于活跃维护状态
- ✅ 定期更新脚本以支持新版本软件
- ✅ 修复平台兼容性问题
- ✅ 简化脚本结构，提高可维护性

### 最近更新
- 简化 `install-nginx.sh` 脚本，使用默认配置
- 新增 `disable-firewall-selinux.sh` 脚本
- 更新 `config-cursor.sh` 脚本，支持 deploy.sh
- 优化 `install-node_exporter.sh`，支持 GitHub 代理镜像
