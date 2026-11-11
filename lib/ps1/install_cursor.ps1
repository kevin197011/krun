# Copyright (c) 2026 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Error handling
$ErrorActionPreference = 'Stop'

# Usage:
# powershell -ExecutionPolicy Bypass -File install_cursor.ps1
# .\install_cursor.ps1
# .\install_cursor.ps1 -Force  (force reinstall / upgrade)
#
# Remote exec:
# irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_cursor.ps1 | iex
# $env:FORCE_INSTALL='true'; irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_cursor.ps1 | iex

# Description: Install or upgrade Cursor (User Installer) from official download API

# Parse arguments manually for irm | iex support
$Force = $false
if ($args -contains '-Force' -or $args -contains '-force') {
    $Force = $true
}
if ($env:FORCE_INSTALL -eq 'true') {
    $Force = $true
}

class CursorInstaller {
    [string] $Arch = 'x64'
    [string] $DownloadUrl = ''
    [string] $Version = ''
    [string] $InstallerPath = "$env:TEMP\CursorUserSetup.exe"
    [string] $InstallDir = "$env:LOCALAPPDATA\Programs\cursor"
    [bool] $Force = $false

    [void] DetectArch() {
        $cpu = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
        switch -Regex ($cpu) {
            'ARM64' { $this.Arch = 'arm64' }
            'AMD64|x86_64|x64' { $this.Arch = 'x64' }
            default { throw "unsupported arch: $cpu (need x64 or arm64)" }
        }
    }

    [bool] IsInstalled() {
        return (Test-Path -LiteralPath (Join-Path $this.InstallDir 'Cursor.exe'))
    }

    [void] ResolveDownload() {
        $this.DetectArch()
        $platform = "win32-$($this.Arch)-user"
        $api = "https://cursor.com/api/download?platform=$platform&releaseTrack=stable"
        Write-Host "Resolving Cursor download ($platform)..." -ForegroundColor Cyan
        $ProgressPreference = 'SilentlyContinue'
        $meta = Invoke-RestMethod -Uri $api -Headers @{ 'User-Agent' = 'krun-install-cursor/1.0' }
        if (-not $meta.downloadUrl) {
            throw "Cursor download API returned no downloadUrl for $platform"
        }
        if ($meta.downloadUrl -notlike 'https://downloads.cursor.com/*') {
            throw "unexpected Cursor download URL: $($meta.downloadUrl)"
        }
        $this.DownloadUrl = [string]$meta.downloadUrl
        $this.Version = [string]$meta.version
        $name = Split-Path -Leaf $this.DownloadUrl
        if (-not $name) { $name = "CursorUserSetup-$($this.Arch).exe" }
        $this.InstallerPath = Join-Path $env:TEMP $name
    }

    [void] Download() {
        Write-Host "Downloading Cursor $($this.Version) ..." -ForegroundColor Cyan
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $this.DownloadUrl -OutFile $this.InstallerPath -UseBasicParsing
    }

    [void] Install() {
        Write-Host "Installing Cursor (silent, user scope)..." -ForegroundColor Cyan
        # Inno Setup; !runcode may be ignored — we stop Cursor.exe after install if it launched.
        $argsList = @(
            '/VERYSILENT',
            '/SUPPRESSMSGBOXES',
            '/NORESTART',
            '/SP-',
            '/MERGETASKS=!runcode'
        )
        $process = Start-Process -FilePath $this.InstallerPath -ArgumentList $argsList -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -ne 0 -and $null -ne $process.ExitCode) {
            throw "Cursor installer exited with code: $($process.ExitCode)"
        }

        Start-Sleep -Seconds 2
        Get-Process -Name 'Cursor' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

        if (-not $this.IsInstalled()) {
            throw "Cursor.exe not found after install at: $($this.InstallDir)"
        }
        Write-Host "Cursor $($this.Version) installed/upgraded successfully!" -ForegroundColor Green
        Write-Host "Path: $(Join-Path $this.InstallDir 'Cursor.exe')" -ForegroundColor Gray
    }

    [void] Cleanup() {
        if (Test-Path -LiteralPath $this.InstallerPath) {
            Remove-Item -LiteralPath $this.InstallerPath -Force -ErrorAction SilentlyContinue
        }
    }

    [void] Run() {
        if ($this.IsInstalled() -and -not $this.Force) {
            Write-Host "Cursor is already installed at: $($this.InstallDir)" -ForegroundColor Green
            Write-Host 'Skipping installation. Use -Force to force reinstall/upgrade.' -ForegroundColor Yellow
            return
        }
        if ($this.Force -and $this.IsInstalled()) {
            Write-Host 'Force flag detected. Proceeding with reinstall/upgrade...' -ForegroundColor Yellow
        }

        $this.ResolveDownload()
        $this.Download()
        try {
            $this.Install()
        } finally {
            $this.Cleanup()
        }
    }
}

$installer = [CursorInstaller]::new()
$installer.Force = $Force
$installer.Run()
