# 🚀 Krun - 多语言脚本执行器

一个支持多种编程语言的轻量级脚本管理和执行工具。

## 🌟 主要特性

- 🌐 **多语言支持**: Shell、Python、Ruby、Perl、JavaScript 等 12 种语言
- 🧠 **智能检测**: 自动识别脚本语言和解释器
- 🎨 **美观界面**: 彩色分组显示，友好的用户体验
- 🛠️ **多版本**: Python、Shell、Go、Ruby、Perl 五种实现版本

## 🚀 快速开始

### 安装
```bash
curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/deploy.sh | bash
```

### 查看脚本列表
```bash
krun list
```

### 执行脚本
```bash
# 按编号执行
krun 1

# 按名称执行
krun hello-world.sh

# 调试模式
krun 1 --debug
```

## 📋 支持的语言

| 语言 | 扩展名 | 解释器 |
|-----|--------|--------|
| 🐚 Shell/Bash | `.sh`, `.bash`, `.zsh`, `.fish` | bash, zsh, fish |
| 🐍 Python | `.py`, `.python` | python3, python |
| 💎 Ruby | `.rb`, `.ruby` | ruby |
| 🐪 Perl | `.pl`, `.perl` | perl |
| 🟨 JavaScript | `.js`, `.javascript` | node |
| 📄 其他 | `.lua`, `.r`, `.php`, `.ps1` 等 | lua, Rscript, php, powershell |

## 🎯 使用示例

```bash
# 查看所有可用脚本
krun list

# 执行 Shell 脚本
krun install-docker.sh

# 执行 Python 脚本
krun setup-environment.py

# 执行 Ruby 脚本
krun deploy-app.rb

# 查看系统状态
krun status

# 查看支持的语言
krun languages

# 获取帮助
krun help
```

## 🛠️ 多版本工具

```bash
# Python 版本 (推荐)
python3 bin/krun list

# Shell 版本 (无依赖)
./bin/krun.sh list

# Go 版本 (高性能)
go run bin/krun-go/krun.go list

# Ruby 版本
ruby bin/krun.rb list

# Perl 版本
perl bin/krun.pl list
```

## 📁 脚本库

当前包含 **57** 个精选脚本：

- 🛠️ 系统配置 (SSH、Vim、Locale)
- 📦 软件安装 (Docker、Python、Ruby、Go)
- 🔧 开发工具 (Git、环境配置)
- ☁️ 云服务 (AWS CLI、Google Cloud)
- 🗄️ 数据库工具 (Redis、MySQL)
- 🌐 网络配置 (Nginx、代理)

## 📜 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

---

更多详细信息请查看 [完整 README](README.md)