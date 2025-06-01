# 🎨 Krun 输出示例演示

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

## 🏃 执行示例

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

## 📚 帮助信息示例 (krun help)

```
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

## 🎭 多版本工具输出

### Python 版本
```bash
$ python3 bin/krun version
Krun Multi-Language Script Runner v2.0
Copyright (c) 2023 kk
MIT License
```

### Shell 版本
```bash
$ ./bin/krun.sh version
Krun Multi-Language Script Runner v2.0 (Shell)
Copyright (c) 2023 kk
MIT License
```

### Go 版本
```bash
$ go run bin/krun-go/krun.go version
Krun Multi-Language Script Runner v2.0 (Go)
Copyright (c) 2023 kk
MIT License
```

### Ruby 版本
```bash
$ ruby bin/krun.rb version
Krun Multi-Language Script Runner v2.0 (Ruby)
Copyright (c) 2023 kk
MIT License
```

### Perl 版本
```bash
$ perl bin/krun.pl version
Krun Multi-Language Script Runner v2.0 (Perl)
Copyright (c) 2023 kk
MIT License
```