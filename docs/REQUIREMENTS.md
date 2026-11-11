# Krun 需求文档

## 背景与目标

Krun 是运维脚本工具集（Shell + Python）。本轮将上游 [kevin197011/windows-utils](https://github.com/kevin197011/windows-utils)（MIT）的 Windows PowerShell 安装/配置能力并入本仓，统一用 `krun` 清单与远程执行入口。

**非目标**

- 不把 windows-utils 的 OpenSpec / 独立 README / 独立仓库生命周期搬进 krun
- 不把 Windows 安装逻辑改写成 Python handlers（Windows 仍用 `.ps1`）
- 不在本机 macOS/Linux 上执行 Windows 安装验收（仅做清单、解析、语法级检查）

### 上游对照

| 上游行为 | 我方落点 | 备注 |
| --- | --- | --- |
| `lib/*.ps1` kebab-case | `lib/ps1/*.ps1` snake_case | 默认按本仓命名，待点名再改 |
| `meta/lib-manifest.json` → `files[]` | `meta/lib-manifest.json` → `ps1[]` | 与 `sh`/`py` 并列 |
| `install-all.ps1` 跑全部 lib | `install_windows_all.ps1` 只跑 `install_*.ps1`（不含自身与 config） | 默认按本仓，待点名再改 |
| remote URL → windows-utils | raw → `kevin197011/krun/main/lib/ps1/` | |
| 独立 `irm \| iex` | 保留；另支持 `krun install_chrome.ps1` | |

## 用户与权限

- 运维在 **Windows** 上以管理员或当前用户运行 PowerShell 脚本
- 时区/NTP、多数系统目录安装需要 Administrator
- `-Force` / `$env:FORCE_INSTALL='true'` 强制重装

## 功能需求

### FR-KRUN-WIN-01 目录与命名

`lib/ps1/` 存放 Windows 脚本；文件名 snake_case（如 `install_chrome.ps1`）。

**验收**：`meta/lib-manifest.json` 的 `ps1` 列出全部 `lib/ps1/*.ps1`。

### FR-KRUN-WIN-02 安装脚本行为

并入并保持上游行为（已装跳过；`-Force` / `FORCE_INSTALL` 强制）：

| 脚本 | 行为 |
| --- | --- |
| `install_winget.ps1` | 从 GitHub release 安装/升级 winget |
| `install_chrome.ps1` | 官方静默安装 Chrome |
| `install_bandizip.ps1` | 官方静默安装 Bandizip |
| `install_snipaste.ps1` | 便携安装到 `%LOCALAPPDATA%\Snipaste` |
| `install_obs.ps1` | 官方/CDN 安装 OBS Studio |
| `install_caddy.ps1` | 官方 Windows amd64 二进制装到 Program Files 并入 PATH |
| `install_vscode.ps1` | VS Code System Installer |
| `config_timezone_utc8_ntp.ps1` | 时区 China Standard Time + NTP |
| `disable_firewall.ps1` | 关闭 Domain/Private/Public 全部防火墙配置文件（需管理员） |
| `config_remote.ps1` | 全自动启用 RDP + WinRM、服务自启；防火墙任一配置文件开启才加规则，全关则跳过（需管理员；可用环境变量关单项） |

**验收**：各脚本注释中的 remote URL 指向 krun；无 `windows-utils` 残留链接。

### FR-KRUN-WIN-03 批量安装

`install_windows_all.ps1`：读远程（或本地旁路）manifest 的 `ps1`，依次执行 `install_*.ps1`（排除自身）。

**验收**：本地旁路时优先跑同目录脚本；支持 `-Force` / `FORCE_INSTALL`。

### FR-KRUN-WIN-04 CLI 支持

`bin/krun` 识别 `.ps1`：`list` / 按名 / 按序号；解释器优先 `pwsh`，否则 `powershell`；执行带 `-ExecutionPolicy Bypass -File`。

**验收**：`krun list` 含 ps1 分组；`krun languages` 提到 PowerShell。

## 非功能需求

- 许可证 MIT；不引入密钥
- 脚本可 `irm … \| iex` 远程执行

## 架构概览

```
lib/sh/*.sh      → bash
lib/py/scripts/  → python3 + krun handlers
lib/ps1/*.ps1    → pwsh/powershell（Windows）
meta/lib-manifest.json → { sh, py, ps1 }
```

## 测试验收清单

1. `rake lib:manifest` 写出 `ps1` 数组且含 9 个脚本  
2. `./bin/krun list` 显示 PowerShell 分组  
3. `rg windows-utils lib/ps1` 无命中  
4. 有 `pwsh` 时对脚本做解析冒烟（`-Command` 解析 class 定义）；无 Windows 不跑真实安装  

## 变更记录

| 版本 | 日期 | 说明 |
| --- | --- | --- |
| — | 2026-11-11 | 并入 windows-utils → `lib/ps1` |

## 开发进度记录

### 2026-11-11

- **做了什么**：上游 windows-utils 行为并入 krun `lib/ps1`；扩展 manifest / `bin/krun` / Rakefile / README  
- **决策**：snake_case；批量脚本名 `install_windows_all`；config 与 install 分开；不移植 OpenSpec  
- **验证**：
  - `rake lib:manifest` → sh:84 py:82 ps1:9
  - `python3 -m py_compile bin/krun` 通过
  - `./bin/krun list` 显示 PowerShell 分组；`languages` 含 powershell
  - `rg windows-utils lib/ps1` 无命中
  - 本机无 pwsh：跳过真实安装；Windows 机人工验收  
- **遗留**：真实 Windows 安装冒烟  

### 2026-11-11（disable_firewall）

- **做了什么**：新增 `lib/ps1/disable_firewall.ps1`，关闭 Domain/Private/Public 防火墙  
- **验证**：`rake lib:manifest` → ps1:10；`krun list` 可见 `disable_firewall.ps1`  
- **遗留**：需在 Windows 管理员 PowerShell 上实测

### 2026-11-11（config_remote）

- **做了什么**：新增 `lib/ps1/config_remote.ps1`（RDP + WinRM + 防火墙规则 + 服务自启）
- **决策**：默认开 NLA；可用 `KRUN_REMOTE_RDP/WINRM/NLA=false` 关单项；Home 版跳过 RDP
- **验证**：`rake lib:manifest` 含该脚本；`krun list` 可见
- **遗留**：需 Windows 管理员环境实测

