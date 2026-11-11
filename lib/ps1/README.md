# lib/ps1 — Windows PowerShell scripts

Windows-only install/config scripts. Discovered via `meta/lib-manifest.json` → `ps1[]` and runnable as:

```powershell
irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/<name>.ps1 | iex
# or (with krun + pwsh/powershell on PATH)
krun <name>.ps1
```

## Scripts

| Name | Purpose |
|------|---------|
| `install_winget.ps1` | Install/upgrade winget |
| `install_chrome.ps1` | Google Chrome |
| `install_bandizip.ps1` | Bandizip |
| `install_snipaste.ps1` | Snipaste (portable) |
| `install_obs.ps1` | OBS Studio |
| `install_caddy.ps1` | Caddy binary + PATH |
| `install_vscode.ps1` | VS Code system installer |
| `install_windows_all.ps1` | Run all `install_*.ps1` from manifest |
| `config_timezone_utc8_ntp.ps1` | China Standard Time + NTP |
| `disable_firewall.ps1` | Disable Domain/Private/Public firewall |
| `config_remote.ps1` | Enable RDP + WinRM; add firewall rules only if firewall is on |

## Conventions

- File names: `snake_case.ps1`
- Prefer idempotent skip when already installed; reinstall with `-Force` or `$env:FORCE_INSTALL='true'`
- Admin required for firewall / RDP / WinRM / most Program Files installs
- After adding a script: `rake lib:manifest`
- New script scaffold: `templates/powershell.ps1.erb` (`@year` / `@action` / `@name`)

## History

Merged from the former `kevin197011/windows-utils` repo (now obsolete). Authoritative product docs: `docs/REQUIREMENTS.md`, root `README.md`.
