# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Error handling
$ErrorActionPreference = 'Stop'

# Usage:
# powershell -ExecutionPolicy Bypass -File install_chrome.ps1
# .\install_chrome.ps1
# .\install_chrome.ps1 -Force  (force reinstall)
#
# Remote exec:
# irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_chrome.ps1 | iex
# $env:FORCE_INSTALL='true'; irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_chrome.ps1 | iex

# Description: Install or upgrade Google Chrome from official installer (no winget)

# Parse arguments manually for irm | iex support
$Force = $false
if ($args -contains "-Force" -or $args -contains "-force") {
    $Force = $true
}

if ($env:FORCE_INSTALL -eq 'true') {
    $Force = $true
}

class ChromeInstaller {
    [string] $DownloadUrl = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
    [string] $InstallerPath = "$env:TEMP\chrome_installer.exe"
    [string] $InstallDir = "$env:ProgramFiles\Google\Chrome\Application"
    [bool] $Force = $false

    [bool] IsInstalled() {
        if (Test-Path -Path "$($this.InstallDir)\chrome.exe") {
            return $true
        }
        return $false
    }

    [void] Download() {
        Write-Host "Downloading Google Chrome installer..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $this.DownloadUrl -OutFile $this.InstallerPath -UseBasicParsing
    }

    [void] Install() {
        Write-Host "Installing Google Chrome (silent)..." -ForegroundColor Cyan
        $process = Start-Process -FilePath $this.InstallerPath -ArgumentList "/silent", "/install" -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -ne 0) {
            throw "Chrome installer exited with code: $($process.ExitCode)"
        }
        Write-Host "Google Chrome installed/upgraded successfully!" -ForegroundColor Green
    }

    [void] Cleanup() {
        Remove-Item -Path $this.InstallerPath -Force -ErrorAction SilentlyContinue
    }

    [void] Run() {
        if ($this.IsInstalled() -and -not $this.Force) {
            Write-Host "Google Chrome is already installed." -ForegroundColor Green
            Write-Host "Skipping installation. Use -Force to force reinstall." -ForegroundColor Yellow
            return
        }
        
        $this.Download()
        try {
            $this.Install()
        } finally {
            $this.Cleanup()
        }
    }
}

# Main execution
$installer = [ChromeInstaller]::new()
$installer.Force = $Force
$installer.Run()
