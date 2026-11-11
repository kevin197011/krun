# Krun 需求文档

## 背景与目标

Krun 是运维脚本工具集：`lib/sh`（bash）、`lib/py`（Python）、`lib/ps1`（Windows PowerShell），由 `bin/krun` + `meta/lib-manifest.json` 统一发现与执行。

本轮将上游 [kevin197011/windows-utils](https://github.com/kevin197011/windows-utils)（MIT）的 Windows 能力并入本仓；**原独立仓废弃，以 krun `lib/ps1` 为准**。

**非目标**

- 不搬 OpenSpec / 独立仓生命周期
- 不把 Windows 安装逻辑改写成 Python handlers
- 不在 macOS/Linux CI 上做真实 Windows 安装验收（仅清单 / 解析 / 文档）

### 上游对照

| 上游行为 | 我方落点 | 备注 |
| --- | --- | --- |
| `lib/*.ps1` kebab-case | `lib/ps1/*.ps1` snake_case | 默认按本仓命名 |
| `meta/lib-manifest.json` → `files[]` | `ps1[]` 与 `sh`/`py` 并列 | |
| `install-all.ps1` | `install_windows_all.ps1`（只跑 `install_*.ps1`，不含自身与 config） | |
| remote → windows-utils | `raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/` | |

## 用户与权限

- Linux/mac：多数脚本需 root/sudo
- Windows：装机 / 防火墙 / 远程配置通常需 Administrator
- Windows 强制重装：`-Force` 或 `$env:FORCE_INSTALL='true'`

## 功能需求

### FR-KRUN-WIN-01 目录与命名

`lib/ps1/` 存放 Windows 脚本；`snake_case.ps1`。

**验收**：`meta/lib-manifest.json` 的 `ps1` 列出全部 `lib/ps1/*.ps1`（当前 11 个）。

### FR-KRUN-WIN-02 安装与配置脚本

| 脚本 | 行为 |
| --- | --- |
| `install_winget.ps1` | GitHub release 安装/升级 winget |
| `install_chrome.ps1` | 官方静默安装 Chrome |
| `install_bandizip.ps1` | 官方静默安装 Bandizip |
| `install_snipaste.ps1` | 便携安装到 `%LOCALAPPDATA%\Snipaste` |
| `install_obs.ps1` | 安装 OBS Studio |
| `install_caddy.ps1` | 官方 Windows amd64 二进制 → Program Files + PATH |
| `install_vscode.ps1` | VS Code System Installer |
| `config_timezone_utc8_ntp.ps1` | China Standard Time + NTP |
| `disable_firewall.ps1` | 关闭 Domain/Private/Public 全部防火墙配置文件 |
| `config_remote.ps1` | 启用 RDP + WinRM、服务自启；**防火墙任一配置文件开启才加规则，全关则跳过** |
| `install_windows_all.ps1` | 读 manifest `ps1`，依次执行 `install_*.ps1`（排除自身） |

**验收**：脚本内 remote URL 指向 krun；`lib/ps1` 无 `windows-utils` 链接。

### FR-KRUN-WIN-03 批量安装

见上表 `install_windows_all.ps1`；本地优先同目录文件，否则拉 raw。

### FR-KRUN-WIN-04 CLI

`bin/krun` 识别 `.ps1`：list / 按名 / 按序号；解释器 `pwsh` 优先，否则 `powershell`；执行带 `-NoProfile -ExecutionPolicy Bypass -File`。

**验收**：`krun list` 有 PowerShell 分组；`krun languages` 含 powershell。

## 非功能需求

- MIT；不提交密钥
- Windows 脚本可 `irm … \| iex`

## 架构概览

```
lib/sh/*.sh           → bash
lib/py/*.py   → python3 + krun handlers
lib/ps1/*.ps1         → pwsh / powershell（Windows）
meta/lib-manifest.json → { sh, py, ps1 }
bin/krun              → 解析清单并调用解释器
```

## 测试验收清单

1. `rake lib:manifest` → 含 `ps1` 且与 `lib/ps1` 一致  
2. `./bin/krun list` 显示 PowerShell 分组  
3. `rg windows-utils lib/ps1` 无命中  
4. 真实安装 / 关防火墙 / 远程配置：Windows 管理员环境人工验收  

## 变更记录

| 版本 | 日期 | 说明 |
| --- | --- | --- |
| — | 2026-11-11 | 并入 windows-utils → `lib/ps1`；`disable_firewall` / `config_remote`；CLI 支持 ps1 |

## 开发进度记录

### 2026-11-11

- **做了什么**：windows-utils → `lib/ps1`；`bin/krun` / Rakefile / manifest；`disable_firewall.ps1`；`config_remote.ps1`（防火墙开才加规则）  
- **决策**：snake_case；批量名 `install_windows_all`；原仓废弃只认 krun；Home 版跳过 RDP  
- **验证**：manifest sh:84 py:82 ps1:11；`krun list` / `languages`；`rg windows-utils lib/ps1` 无命中  
- **文档**：README / 本文件 / `lib/ps1/README.md` / vault hub 同步  
- **遗留**：Windows 机真实冒烟；原 GitHub 仓若仍在需有 delete_repo 权限的 PAT 删除

### 2026-11-11（flatten lib/py）

- **做了什么**：去掉 registry/handlers/bootstrap；`lib/py/*.py` 改为与 sh/ps1 一样的独立完整脚本
- **验证**：`python3 -m py_compile` 全部 scripts；`hello_world.py` 可跑；scripts 内无 `krun.registry` import
- **遗留**：部分 install_* 仍是「薄装包」逻辑（未与同名 sh 功能深度对齐）

