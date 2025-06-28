# 🚀 Krun - Multi-Language Script Runner
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

一个轻量级的多语言脚本管理和执行工具，支持从 GitHub 仓库远程运行各种编程语言的脚本。

## ✨ 核心特性

### 🌐 多语言支持
- **Shell/Bash**: `.sh`, `.bash`, `.zsh`, `.fish`
- **Python**: `.py`, `.python` (支持 python3/python)
- **Ruby**: `.rb`, `.ruby`
- **Perl**: `.pl`, `.perl`
- **JavaScript**: `.js`, `.javascript` (Node.js)
- **Lua**: `.lua`
- **R**: `.r`, `.R` (Rscript)
- **PHP**: `.php`
- **Swift**: `.swift`
- **Groovy**: `.groovy`
- **Scala**: `.scala`
- **PowerShell**: `.ps1`

### 🧠 智能解释器检测
- 🔍 基于文件扩展名自动检测
- 📜 Shebang 行解析支持
- ✅ 系统可用性自动检查
- 🔄 优雅的回退机制

### 🎨 美观的用户界面
- 📊 按语言分组显示脚本
- 🎯 彩色图标和状态指示
- 📈 统计信息展示
- 💡 友好的使用提示

### 🛠️ 多版本实现
- **Python**: 主版本，功能最完整
- **Shell**: 纯 Bash 实现，无依赖
- **Go**: 高性能编译版本
- **Ruby**: 面向对象实现
- **Perl**: 传统脚本实现

## 📦 安装

### 快速安装
```bash
# 默认安装
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/deploy.sh | bash

# 自定义安装路径
export deploy_path="/your/custom/path"
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/deploy.sh | bash
```

### 手动安装
```bash
# 克隆仓库
git clone https://github.com/kevin197011/krun.git
cd krun

# 添加到 PATH
export PATH="$PWD/bin:$PATH"

# 或者创建符号链接
ln -s $PWD/bin/krun /usr/local/bin/krun
```

## 🎯 使用方法

### 📋 列出所有脚本

```bash
$ krun list
🚀 Krun Multi-Language Script Collection
==================================================

📊 Total Scripts: 57
📁 Categories: 6

🐚 SHELL Scripts (45 files)
────────────────────────────────────────
    [ 1] hello-world.sh
    [ 2] install-docker.sh
    [ 3] config-system.sh
    [ 4] install-nginx.sh
    ...

🐍 PYTHON Scripts (8 files)
────────────────────────────────────────
    [46] install-python3.py
    [47] setup-virtualenv.py
    ...

💎 RUBY Scripts (4 files)
────────────────────────────────────────
    [54] install-ruby.rb
    [55] config-rails.rb
    ...

💡 Usage: krun <number> or krun <script_name>
🔍 Debug: krun <number> --debug
==================================================
```

### 🏃 执行脚本

#### 按编号执行
```bash
$ krun 1
Executing hello-world.sh with bash...
Hello, World!
```

#### 按名称执行
```bash
$ krun install-python3.py
Executing install-python3.py with python3...
Installing Python 3...
✅ Python 3 installed successfully!
```

#### 执行不同语言的脚本
```bash
# Shell 脚本
$ krun config-system.sh

# Python 脚本
$ krun setup-environment.py

# Ruby 脚本
$ krun deploy-app.rb

# JavaScript 脚本
$ krun build-assets.js

# Perl 脚本
$ krun backup-database.pl
```

### 🔍 调试模式

查看脚本内容和详细信息：

```bash
$ krun 5 --debug
=== Script Debug Information ===
Filename: config-system.sh
URL: https://raw.githubusercontent.com/kevin197011/krun/main/lib/config-system.sh
File extension: .sh
Detected interpreter: bash
Shebang interpreter: bash

=== Script Content ===
#!/usr/bin/env bash
# Script content here...
```

### 📊 系统状态

检查支持的语言和解释器：

```bash
$ krun status
Krun ready!
Supported interpreters:
  .sh: bash
  .py: python3, python
  .rb: ruby
  .pl: perl
  .js: node
  .lua: lua
  .php: php
```

### 🌍 语言支持

查看所有支持的语言：

```bash
$ krun languages
Supported script languages and extensions:

  ✓ Shell/Bash: .sh .bash .zsh .fish (bash, zsh)
  ✓ Python: .py .python (python3, python)
  ✓ Ruby: .rb .ruby (ruby)
  ✓ Perl: .pl .perl (perl)
  ✓ JavaScript (Node.js): .js .javascript (node)
  ✗ Lua: .lua (Not available)
  ✓ R: .r .R (Rscript)
  ✗ Swift: .swift (Not available)
```

### 📚 帮助信息

```bash
$ krun help
Krun Multi-Language Script Runner

Usage:
  krun list                    - List all available scripts
  krun <number>                - Execute script by number
  krun <script_name>           - Execute script by name
  krun <number|script> --debug - Show script content and debug info
  krun status                  - Show system status and available interpreters
  krun languages               - Show supported languages
  krun version                 - Show version information
  krun help                    - Show this help message

Examples:
  krun 1                       - Execute first script
  krun hello-world.sh          - Execute hello-world.sh
  krun install-python3.py      - Execute Python script
  krun config-system.rb        - Execute Ruby script
  krun 5 --debug               - Show debug info for script #5
```

## 🎭 多版本工具

### Python 版本 (推荐)
```bash
python3 bin/krun list
```

### Shell 版本 (无依赖)
```bash
./bin/krun.sh list
```

### Go 版本 (高性能)
```bash
cd bin/krun-go && go run krun.go list
```

### Ruby 版本
```bash
ruby bin/krun.rb list
```

### Perl 版本
```bash
perl bin/krun.pl list
```

## 🏗️ 工作原理

1. **脚本检测**: 自动识别脚本语言和所需解释器
2. **远程获取**: 从 GitHub 仓库下载脚本内容
3. **临时执行**: 在临时文件中安全执行脚本
4. **自动清理**: 执行完成后自动清理临时文件

## 🔧 高级功能

### 环境变量支持
```bash
# 自定义基础 URL
export KRUN_BASE_URL="https://your-custom-repo.com"

# 自定义用户代理
export KRUN_USER_AGENT="YourCustomAgent/1.0"
```

### 批量执行
```bash
# 执行多个脚本
for script in install-docker.sh config-system.sh; do
    krun "$script"
done
```

### 集成到 CI/CD
```yaml
# GitHub Actions 示例
- name: Setup Environment
  run: |
    curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/deploy.sh | bash
    krun install-dependencies.sh
    krun setup-environment.py
```

## 📁 脚本库

当前脚本库包含 **57** 个高质量脚本，涵盖：

- 🛠️ **系统配置**: SSH、Vim、Locale 设置
- 📦 **软件安装**: Docker、Python、Ruby、Go 等
- 🔧 **开发工具**: Git 配置、开发环境设置
- ☁️ **云服务**: AWS CLI、Google Cloud SDK
- 🗄️ **数据库**: Redis、MySQL 工具
- 🌐 **网络工具**: Nginx、代理配置

## 🤝 贡献指南

欢迎贡献新的脚本或改进现有功能！

### 添加新脚本
1. 在 `lib/` 目录下添加脚本文件
2. 确保脚本遵循项目格式规范
3. 更新 `resources/krun.json` 文件
4. 提交 Pull Request

### 脚本格式规范
```bash
#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/your-script.sh | bash

# 脚本内容...
```

## 🛡️ 安全考虑

- ✅ 脚本在隔离的临时环境中执行
- ✅ 自动清理临时文件
- ✅ 用户中断支持 (Ctrl+C)
- ✅ 错误处理和回滚机制
- ⚠️ 请仅执行来自可信源的脚本

## 📊 兼容性

### 操作系统
- ✅ macOS 10.15+
- ✅ Ubuntu 18.04+
- ✅ CentOS 7+
- ✅ Windows (WSL)

### 解释器要求
- `bash` 4.0+ (Shell 脚本)
- `python` 2.7+ 或 `python3` 3.6+ (Python 脚本)
- `ruby` 2.0+ (Ruby 脚本)
- `perl` 5.10+ (Perl 脚本)
- `node` 10.0+ (JavaScript 脚本)

## 📈 版本历史

### v2.0 (当前版本)
- 🎉 新增多语言支持
- 🎨 美化用户界面
- 🧠 智能解释器检测
- 🛠️ 多版本实现
- 📊 详细统计信息

### v1.0
- 🚀 基础 Shell 脚本执行
- 📋 脚本列表功能
- 🔍 调试模式

## 📜 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

感谢所有贡献者和用户的支持！

---

**Made with ❤️ by [kevin197011](https://github.com/kevin197011)**