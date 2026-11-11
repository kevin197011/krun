# Copyright (c) 2026 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Error handling
$ErrorActionPreference = 'Stop'

# Usage:
# powershell -ExecutionPolicy Bypass -File config_remote.ps1
# .\config_remote.ps1
#
# Remote exec:
# irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/config_remote.ps1 | iex
#
# Env (optional):
#   $env:KRUN_REMOTE_NLA='false'     # disable Network Level Authentication (default: true)
#   $env:KRUN_REMOTE_WINRM='false'   # skip WinRM / PowerShell Remoting (default: true)
#   $env:KRUN_REMOTE_RDP='false'     # skip Remote Desktop (default: true)
#
# Note: Requires Administrator. Enables RDP + WinRM.
# Firewall rules are added only when at least one firewall profile is enabled;
# if all profiles are disabled, firewall steps are skipped.
# Compatible with Windows PowerShell 5.1 (no class method default params).

# Description: Fully automate Windows remote access (Remote Desktop + WinRM)

class RemoteServiceConfigurator {
    [bool] $EnableRdp = $true
    [bool] $EnableWinRm = $true
    [bool] $RequireNla = $true

    RemoteServiceConfigurator() {
        if ($env:KRUN_REMOTE_RDP -eq 'false') { $this.EnableRdp = $false }
        if ($env:KRUN_REMOTE_WINRM -eq 'false') { $this.EnableWinRm = $false }
        if ($env:KRUN_REMOTE_NLA -eq 'false') { $this.RequireNla = $false }
    }

    [bool] IsAdmin() {
        $currentPrincipal = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
        return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    [bool] IsWindowsHome() {
        try {
            $edition = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").EditionID
            return ($edition -match 'Core')
        } catch {
            return $false
        }
    }

    # True when any Domain/Private/Public profile is enabled.
    [bool] IsFirewallActive() {
        if (Get-Command Get-NetFirewallProfile -ErrorAction SilentlyContinue) {
            $profiles = @(Get-NetFirewallProfile -Profile Domain, Private, Public -ErrorAction SilentlyContinue)
            foreach ($p in $profiles) {
                if ($p.Enabled) {
                    return $true
                }
            }
            return $false
        }

        # Fallback: parse netsh (ON means active)
        try {
            $out = & netsh advfirewall show allprofiles state 2>$null | Out-String
            if ($out -match '(?i)State\s+ON') {
                return $true
            }
        } catch { }
        return $false
    }

    # PS 5.1: class methods cannot have default parameter values.
    [void] EnsureService([string] $Name, [string] $StartupType) {
        if ([string]::IsNullOrWhiteSpace($StartupType)) {
            $StartupType = "Automatic"
        }
        $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
        if (-not $svc) {
            Write-Host "  skip: service $Name not found" -ForegroundColor Yellow
            return
        }
        if ($svc.StartType -ne $StartupType) {
            Set-Service -Name $Name -StartupType $StartupType
        }
        if ($svc.Status -ne "Running") {
            Start-Service -Name $Name
            Write-Host "  started $Name" -ForegroundColor Green
        } else {
            Write-Host "  $Name already running" -ForegroundColor Green
        }
    }

    [void] EnableFirewallGroup([string] $DisplayGroup) {
        if (-not (Get-Command Enable-NetFirewallRule -ErrorAction SilentlyContinue)) {
            Write-Host "  skip firewall group '$DisplayGroup' (Enable-NetFirewallRule missing)" -ForegroundColor Yellow
            return
        }
        $rules = Get-NetFirewallRule -DisplayGroup $DisplayGroup -ErrorAction SilentlyContinue
        if (-not $rules) {
            Write-Host "  firewall group not found: $DisplayGroup" -ForegroundColor Yellow
            return
        }
        Enable-NetFirewallRule -DisplayGroup $DisplayGroup -ErrorAction SilentlyContinue
        Write-Host "  firewall group enabled: $DisplayGroup" -ForegroundColor Green
    }

    [void] EnsureAllowRule([string] $Name, [string] $DisplayName, [int] $Port) {
        if (-not (Get-Command New-NetFirewallRule -ErrorAction SilentlyContinue)) {
            return
        }
        $existing = Get-NetFirewallRule -Name $Name -ErrorAction SilentlyContinue
        if (-not $existing) {
            New-NetFirewallRule -Name $Name -DisplayName $DisplayName `
                -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort $Port | Out-Null
            Write-Host "  created firewall rule $Name" -ForegroundColor Green
        } else {
            Enable-NetFirewallRule -Name $Name -ErrorAction SilentlyContinue
            Write-Host "  firewall rule $Name enabled" -ForegroundColor Green
        }
    }

    # Add/enable rules only when firewall is on; skip entirely when all profiles are off.
    [void] ConfigureFirewallForRemote([string] $DisplayGroup, [string] $RuleName, [string] $RuleDisplayName, [int] $Port) {
        if (-not $this.IsFirewallActive()) {
            Write-Host "  firewall disabled on all profiles -- skip rules ($DisplayGroup / $RuleName)" -ForegroundColor Yellow
            return
        }
        Write-Host "  firewall active -- ensuring rules..." -ForegroundColor Cyan
        $this.EnableFirewallGroup($DisplayGroup)
        $this.EnsureAllowRule($RuleName, $RuleDisplayName, $Port)
    }

    [void] ConfigureRdp() {
        Write-Host "Configuring Remote Desktop..." -ForegroundColor Cyan

        if ($this.IsWindowsHome()) {
            Write-Host "  Windows Home edition: RDP host is not supported. Skipping RDP." -ForegroundColor Yellow
            return
        }

        $tsKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
        $rdpKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"

        Set-ItemProperty -Path $tsKey -Name "fDenyTSConnections" -Value 0 -Type DWord
        Write-Host "  fDenyTSConnections = 0" -ForegroundColor Green

        $nlaValue = if ($this.RequireNla) { 1 } else { 0 }
        if (Test-Path $rdpKey) {
            Set-ItemProperty -Path $rdpKey -Name "UserAuthentication" -Value $nlaValue -Type DWord
            Write-Host "  NLA (UserAuthentication) = $nlaValue" -ForegroundColor Green
        }

        $this.EnsureService("TermService", "Automatic")
        $this.EnsureService("UmRdpService", "Automatic")
        $this.ConfigureFirewallForRemote(
            "Remote Desktop",
            "Krun-RDP-TCP-3389",
            "Krun Remote Desktop (TCP-3389)",
            3389
        )
    }

    [void] ConfigureWinRm() {
        Write-Host "Configuring WinRM / PowerShell Remoting..." -ForegroundColor Cyan

        if (-not (Get-Command Enable-PSRemoting -ErrorAction SilentlyContinue)) {
            Write-Host "  Enable-PSRemoting not available; trying winrm quickconfig" -ForegroundColor Yellow
            & winrm quickconfig -quiet -force
            if ($LASTEXITCODE -ne 0) {
                throw "winrm quickconfig failed with exit code $LASTEXITCODE"
            }
        } else {
            # SkipNetworkProfileCheck: allow on Public networks for unattended lab/server setup
            Enable-PSRemoting -Force -SkipNetworkProfileCheck
        }

        $this.EnsureService("WinRM", "Automatic")
        $this.ConfigureFirewallForRemote(
            "Windows Remote Management",
            "Krun-WinRM-HTTP-5985",
            "Krun WinRM HTTP (TCP-5985)",
            5985
        )

        try {
            Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $false -ErrorAction SilentlyContinue
            Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true -ErrorAction SilentlyContinue
        } catch {
            Write-Host "  WinRM auth tweak skipped: $_" -ForegroundColor Yellow
        }
    }

    [void] ShowStatus() {
        Write-Host ""
        Write-Host "Remote service status:" -ForegroundColor Cyan

        $deny = $null
        try {
            $deny = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections).fDenyTSConnections
        } catch { }
        $rdpState = if ($deny -eq 0) { "ENABLED" } else { "DISABLED/UNKNOWN" }
        Write-Host ("  RDP              : {0}" -f $rdpState)

        foreach ($name in @("TermService", "UmRdpService", "WinRM")) {
            $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
            if ($svc) {
                Write-Host ("  {0,-16}: {1} ({2})" -f $name, $svc.Status, $svc.StartType)
            } else {
                Write-Host ("  {0,-16}: not found" -f $name) -ForegroundColor Yellow
            }
        }

        try {
            $listeners = Get-ChildItem WSMan:\localhost\Listener -ErrorAction SilentlyContinue
            if ($listeners) {
                Write-Host "  WinRM listeners  : $($listeners.Count)"
            }
        } catch { }

        Write-Host ""
        Write-Host "Connect examples:" -ForegroundColor Cyan
        Write-Host "  mstsc /v:<host>                 # Remote Desktop"
        Write-Host "  Enter-PSSession -ComputerName <host> -Credential (Get-Credential)"
    }

    [void] Run() {
        if (-not $this.IsAdmin()) {
            throw "Administrator privileges required. Re-run PowerShell as Administrator."
        }

        if (-not $this.EnableRdp -and -not $this.EnableWinRm) {
            throw "Nothing to do: both KRUN_REMOTE_RDP and KRUN_REMOTE_WINRM are false."
        }

        if ($this.EnableRdp) {
            $this.ConfigureRdp()
        } else {
            Write-Host "Skipping RDP (KRUN_REMOTE_RDP=false)" -ForegroundColor Yellow
        }

        if ($this.EnableWinRm) {
            $this.ConfigureWinRm()
        } else {
            Write-Host "Skipping WinRM (KRUN_REMOTE_WINRM=false)" -ForegroundColor Yellow
        }

        Write-Host "Remote services configuration completed." -ForegroundColor Green
        $this.ShowStatus()
    }
}

# Main execution
$configurator = [RemoteServiceConfigurator]::new()
$configurator.Run()
