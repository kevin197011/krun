# 🎨 Krun 输出示例演示

本文档展示了 Krun 多语言脚本执行器的各种输出效果和使用场景。

## 📋 美化的脚本列表 (krun list)

```
🚀 Krun Multi-Language Script Collection
==================================================

📊 Total Scripts: 57
📁 Categories: 6

🐚 SHELL Scripts (45 files)
────────────────────────────────────────
    [ 1] hello-world.sh
    [ 2] install-docker.sh
    [ 3] config-system.sh
    [ 4] config-ssh.sh
    [ 5] config-vim.sh
    [ 6] install-nginx.sh
    [ 7] install-golang.sh
    [ 8] install-python3.sh
    [ 9] install-ruby.sh
    [10] install-zsh.sh
    [11] install-oh_my_zsh.sh
    [12] install-asdf.sh
    [13] config-git.sh
    [14] install-redis.sh
    [15] install-openjdk.sh
    [16] install-mc.sh
    [17] check-ip.sh
    [18] install-awscli.sh
    [19] config-fstab.sh
    [20] get-host_info.sh
    [21] apply-asdf.sh
    [22] install-elixir.sh
    [23] install-ffmpeg.sh
    [24] install-tinyproxy.sh
    [25] install-gcloud.sh
    [26] install-xtrabackup.sh
    [27] config-locales.sh
    [28] get-ipaddr.sh
    [29] check-system_resources.sh

🐍 PYTHON Scripts (8 files)
────────────────────────────────────────
    [30] setup-virtualenv.py
    [31] install-pip-packages.py
    [32] backup-mysql.py
    [33] deploy-flask-app.py
    [34] data-analysis.py
    [35] web-scraper.py
    [36] email-sender.py
    [37] file-organizer.py

💎 RUBY Scripts (5 files)
────────────────────────────────────────
    [38] setup-rails-env.rb
    [39] deploy-sinatra.rb
    [40] gem-updater.rb
    [41] log-analyzer.rb
    [42] database-migrator.rb

🐪 PERL Scripts (3 files)
────────────────────────────────────────
    [43] backup-files.pl
    [44] parse-apache-logs.pl
    [45] system-monitor.pl

🟨 JAVASCRIPT Scripts (4 files)
────────────────────────────────────────
    [46] build-webpack.js
    [47] deploy-node-app.js
    [48] npm-audit-fix.js
    [49] minify-assets.js

📄 OTHER Scripts (2 files)
────────────────────────────────────────
    [50] data-analysis.r
    [51] performance-test.lua

💡 Usage: krun <number> or krun <script_name>
🔍 Debug: krun <number> --debug
==================================================
```

## 🔍 调试模式示例 (krun 1 --debug)

```
=== Script Debug Information ===
Filename: hello-world.sh
URL: https://raw.githubusercontent.com/kevin197011/krun/main/lib/hello-world.sh
File extension: .sh
Detected interpreter: bash
Shebang interpreter: bash

=== Script Content ===
#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/hello-world.sh | bash

echo "🌍 Hello, World from Krun!"
echo "🚀 Multi-language script execution is working!"
```

## 📊 系统状态示例 (krun status)

```
Krun ready!
Supported interpreters:
  .sh: bash
  .bash: bash
  .zsh: zsh
  .py: python3, python
  .python: python3, python
  .rb: ruby
  .ruby: ruby
  .pl: perl
  .perl: perl
  .js: node
  .javascript: node
  .lua: lua
  .r: Rscript
  .R: Rscript
  .php: php
```

## 🌍 语言支持示例 (krun languages)

```
Supported script languages and extensions:

  ✓ Shell/Bash: .sh .bash .zsh .fish (bash, zsh)
  ✓ Python: .py .python (python3, python)
  ✓ Ruby: .rb .ruby (ruby)
  ✓ Perl: .pl .perl (perl)
  ✓ JavaScript (Node.js): .js .javascript (node)
  ✓ Lua: .lua (lua)
  ✓ R: .r .R (Rscript)
  ✓ PHP: .php (php)
  ✗ Swift: .swift (Not available)
  ✗ Groovy: .groovy (Not available)
  ✗ Scala: .scala (Not available)
  ✗ PowerShell: .ps1 (Not available)
```

## 🏃 脚本执行示例

### Shell 脚本执行
```bash
$ krun hello-world.sh
Executing hello-world.sh with bash...
🌍 Hello, World from Krun!
🚀 Multi-language script execution is working!
```

### Python 脚本执行
```bash
$ krun setup-virtualenv.py
Executing setup-virtualenv.py with python3...
🐍 Setting up Python virtual environment...
📦 Installing required packages...
✅ Virtual environment setup completed!
```

### Ruby 脚本执行
```bash
$ krun setup-rails-env.rb
Executing setup-rails-env.rb with ruby...
💎 Setting up Rails development environment...
📦 Installing gems...
✅ Rails environment ready!
```

### JavaScript 脚本执行
```bash
$ krun build-webpack.js
Executing build-webpack.js with node...
🟨 Building assets with Webpack...
📦 Bundling modules...
✅ Build completed successfully!
```

### Perl 脚本执行
```bash
$ krun system-monitor.pl
Executing system-monitor.pl with perl...
🐪 Monitoring system resources...
📊 CPU Usage: 15%
📊 Memory Usage: 45%
📊 Disk Usage: 68%
✅ System monitoring completed!
```

### Lua 脚本执行
```bash
$ krun performance-test.lua
Executing performance-test.lua with lua...
🌙 Running performance tests...
⚡ Test 1: 125ms
⚡ Test 2: 98ms
⚡ Test 3: 156ms
✅ Performance tests completed!
```

### R 脚本执行
```bash
$ krun data-analysis.r
Executing data-analysis.r with Rscript...
📊 Loading dataset...
🔬 Performing statistical analysis...
📈 Generating visualizations...
✅ Analysis complete! Results saved to output.pdf
```

## ⚠️ 错误处理示例

### 脚本不存在
```bash
$ krun non-existent-script.sh
Error: Invalid script number: 999
```

### 解释器不可用
```bash
$ krun test-script.swift
Error: Cannot determine interpreter for test-script.swift
Available interpreters: bash, python3, ruby, perl, node
```

### 网络连接失败
```bash
$ krun 1
Error fetching https://raw.githubusercontent.com/kevin197011/krun/main/lib/hello-world.sh:
Connection timeout
```

### 脚本执行失败
```bash
$ krun faulty-script.sh
Executing faulty-script.sh with bash...
faulty-script.sh: line 15: command not found: invalid_command
Error: Script execution failed with exit code 127
```

## 🔧 高级功能演示

### 批量执行脚本
```bash
$ for script in install-docker.sh config-git.sh install-python3.sh; do
    echo "Executing $script..."
    krun "$script"
    echo "✅ Completed: $script"
    echo "---"
done

Executing install-docker.sh...
🐳 Installing Docker...
✅ Docker installed successfully!
✅ Completed: install-docker.sh
---
Executing config-git.sh...
🔧 Configuring Git...
✅ Git configuration completed!
✅ Completed: config-git.sh
---
Executing install-python3.sh...
🐍 Installing Python 3...
✅ Python 3 installed successfully!
✅ Completed: install-python3.sh
---
```

### 环境变量配置
```bash
$ export KRUN_BASE_URL="https://my-custom-repo.com"
$ krun status
Krun ready!
Base URL: https://my-custom-repo.com
Custom configuration detected.
```

### 条件执行
```bash
$ if krun check-system_resources.sh; then
    echo "System resources OK, proceeding with installation..."
    krun install-docker.sh
else
    echo "Insufficient resources, skipping installation."
fi

Executing check-system_resources.sh with bash...
📊 Checking system resources...
✅ CPU: Available
✅ Memory: 8GB available
✅ Disk: 50GB available
System resources OK, proceeding with installation...
Executing install-docker.sh with bash...
🐳 Installing Docker...
✅ Docker installed successfully!
```

## 🎭 多版本工具对比

### 性能对比
```bash
# Python 版本
$ time python3 bin/krun version
Krun Multi-Language Script Runner v2.0
Copyright (c) 2023 kk
MIT License

real    0m0.156s
user    0m0.089s
sys     0m0.067s

# Shell 版本 (更快启动)
$ time ./bin/krun.sh version
Krun Multi-Language Script Runner v2.0 (Shell)
Copyright (c) 2023 kk
MIT License

real    0m0.023s
user    0m0.015s
sys     0m0.008s

# Go 版本 (编译后最快)
$ time go run bin/krun-go/krun.go version
Krun Multi-Language Script Runner v2.0 (Go)
Copyright (c) 2023 kk
MIT License

real    0m0.312s  # 包含编译时间
user    0m0.245s
sys     0m0.067s
```

### 功能对比表
| 功能 | Python | Shell | Go | Ruby | Perl |
|------|--------|-------|----|----- |------|
| 🚀 启动速度 | 中等 | 最快 | 快(编译) | 中等 | 快 |
| 🧠 智能检测 | ✅ 完整 | ✅ 完整 | ✅ 完整 | 🔄 基础 | ✅ 完整 |
| 🎨 美化输出 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 📊 统计信息 | ✅ | ✅ | ✅ | 🔄 | ✅ |
| 🔍 调试模式 | ✅ 详细 | ✅ 详细 | ✅ 详细 | 🔄 基础 | ✅ 详细 |
| 🛠️ 依赖要求 | Python | 无 | Go | Ruby | Perl |

## 🌟 实际使用场景

### DevOps 自动化流程
```bash
# 1. 系统检查
$ krun check-system_resources.sh
📊 Checking system resources...
✅ All systems go!

# 2. 基础环境配置
$ krun config-system.sh
🔧 Configuring system settings...
✅ System configured!

# 3. 开发工具安装
$ krun install-docker.sh && krun install-python3.sh && krun install-nodejs.sh
🐳 Installing Docker...
🐍 Installing Python 3...
🟨 Installing Node.js...
✅ Development environment ready!

# 4. 应用部署
$ krun deploy-flask-app.py
🐍 Deploying Flask application...
🚀 Application deployed successfully!
URL: https://your-app.example.com
```

### CI/CD 集成示例
```yaml
# .github/workflows/deploy.yml
name: Deploy with Krun
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Setup Krun
        run: |
          curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/deploy.sh | bash
          echo "$HOME/.local/bin" >> $GITHUB_PATH

      - name: Deploy Application
        run: |
          krun check-system_resources.sh
          krun install-dependencies.sh
          krun deploy-app.py
          krun run-tests.sh
```

### 开发环境快速搭建
```bash
# 新开发者环境配置
$ echo "Setting up development environment..."
$ krun install-git.sh
$ krun config-git.sh
$ krun install-docker.sh
$ krun install-python3.sh
$ krun setup-virtualenv.py
$ krun install-vscode-extensions.sh
$ echo "✅ Development environment ready!"
```

## 🛠️ 故障排除示例

### 调试网络问题
```bash
$ krun 1 --debug
=== Script Debug Information ===
Filename: hello-world.sh
URL: https://raw.githubusercontent.com/kevin197011/krun/main/lib/hello-world.sh
File extension: .sh
Detected interpreter: bash

Error: HTTP request failed: 404 Not Found

# 解决方案：检查网络连接和 URL
$ curl -I https://raw.githubusercontent.com/kevin197011/krun/main/lib/hello-world.sh
HTTP/2 200
```

### 权限问题
```bash
$ krun install-docker.sh
Executing install-docker.sh with bash...
Error: Permission denied. Please run with sudo or as root.

# 解决方案：使用适当权限
$ sudo krun install-docker.sh
[sudo] password for user:
Executing install-docker.sh with bash...
🐳 Installing Docker...
✅ Docker installed successfully!
```

### 解释器缺失
```bash
$ krun data-analysis.r
Error: Cannot determine interpreter for data-analysis.r
Interpreter 'Rscript' not found.

# 解决方案：安装 R
$ sudo apt-get install r-base
$ krun data-analysis.r
Executing data-analysis.r with Rscript...
📊 R analysis completed!
```

## 📊 性能监控示例

### 执行时间统计
```bash
$ time krun large-dataset-processing.py
Executing large-dataset-processing.py with python3...
🐍 Processing large dataset...
📊 Processing 1M records...
🔄 Progress: 25% complete...
🔄 Progress: 50% complete...
🔄 Progress: 75% complete...
✅ Processing completed!

real    2m34.567s
user    2m12.345s
sys     0m22.222s
```

### 资源使用监控
```bash
$ krun system-monitor.pl &
$ MONITOR_PID=$!
$ krun intensive-task.py
$ kill $MONITOR_PID

Monitor Output:
📊 System Resource Monitor Started
⏰ [14:30:01] CPU: 25% | Memory: 45% | Disk I/O: 15MB/s
⏰ [14:30:02] CPU: 67% | Memory: 58% | Disk I/O: 32MB/s
⏰ [14:30:03] CPU: 89% | Memory: 72% | Disk I/O: 45MB/s
⏰ [14:30:04] CPU: 45% | Memory: 51% | Disk I/O: 12MB/s
📊 Peak CPU: 89% | Peak Memory: 72%
```

## 🎯 最佳实践示例

### 脚本选择建议
```bash
# 查看可用脚本并选择合适的
$ krun list | grep -i docker
    [ 2] install-docker.sh
    [15] docker-cleanup.sh
    [28] docker-compose-setup.sh

# 根据系统选择合适的脚本
$ if command -v apt-get >/dev/null; then
    krun install-docker-ubuntu.sh
elif command -v yum >/dev/null; then
    krun install-docker-centos.sh
else
    krun install-docker.sh  # 通用版本
fi
```

### 日志记录
```bash
# 记录执行日志
$ mkdir -p logs
$ krun install-python3.sh 2>&1 | tee logs/python-install-$(date +%Y%m%d_%H%M%S).log
Executing install-python3.sh with bash...
🐍 Installing Python 3...
📦 Adding Python repository...
📦 Installing Python packages...
✅ Python 3 installed successfully!
Version: Python 3.9.7
```

### 错误处理和重试
```bash
#!/bin/bash
# 带重试机制的脚本执行
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if krun deploy-app.py; then
        echo "✅ Deployment successful!"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "❌ Deployment failed. Retry $RETRY_COUNT/$MAX_RETRIES"
        sleep 10
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "💥 Deployment failed after $MAX_RETRIES attempts"
    exit 1
fi
```

## 📈 使用统计示例

### 命令使用频率
```
Most Used Commands (Last 30 days):
1. krun list               - 156 times
2. krun install-docker.sh  - 89 times
3. krun config-git.sh      - 67 times
4. krun install-python3.sh - 45 times
5. krun status             - 34 times
6. krun help               - 28 times
7. krun languages          - 23 times
```

### 执行成功率
```
Script Execution Statistics:
📊 Total Executions: 1,247
✅ Successful: 1,198 (96.1%)
❌ Failed: 49 (3.9%)

Top Failure Reasons:
1. Network connectivity (45%)
2. Permission denied (32%)
3. Missing dependencies (18%)
4. Script errors (5%)
```

## 🎉 总结

Krun 多语言脚本执行器提供了：

- 🌐 **12种语言支持** - 覆盖主流脚本语言
- 🧠 **智能检测** - 自动选择合适的解释器
- 🎨 **美观界面** - 清晰的分组和状态显示
- 🛠️ **多版本实现** - 适应不同使用场景
- 🔍 **强大调试** - 详细的错误信息和调试模式
- ⚡ **高性能** - 快速启动和执行
- 🛡️ **安全可靠** - 完善的错误处理和清理机制

立即开始使用 Krun，让脚本管理变得简单高效！

```bash
# 立即安装
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/deploy.sh | bash

# 开始使用
krun list
krun hello-world.sh
```

---

*更多信息请查看 [主README文档](../README.md)*