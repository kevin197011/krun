# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Error handling
$ErrorActionPreference = 'Stop'

# Usage:
# powershell -ExecutionPolicy Bypass -File install_bandizip.ps1
# .\install_bandizip.ps1
# .\install_bandizip.ps1 -Force  (force reinstall)
#
# Remote exec:
# irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_bandizip.ps1 | iex
# $env:FORCE_INSTALL='true'; irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_bandizip.ps1 | iex

# Description: Install or upgrade Bandizip from official installer (no winget)

# Parse arguments manually for irm | iex support
$Force = $false
if ($args -contains "-Force" -or $args -contains "-force") {
    $Force = $true
}

if ($env:FORCE_INSTALL -eq 'true') {
    $Force = $true
}

class BandizipInstaller {
    # Official download (dl.php?std-all = Standard edition, all CPUs). Regional mirrors: std-all-us, std-all-eu, std-all-sg, etc.
    [string] $DownloadUrl = "https://www.bandisoft.com/bandizip/dl.php?all"
    [string] $InstallerPath = "$env:TEMP\Bandizip-Setup.exe"
    [string] $InstallDir = "$env:ProgramFiles\Bandizip"
    [bool] $Force = $false

    [bool] IsInstalled() {
        if (Test-Path -Path "$($this.InstallDir)\Bandizip.exe") {
            return $true
        }
        return $false
    }

    [void] Download() {
        Write-Host "Downloading Bandizip installer..." -ForegroundColor Cyan
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $this.DownloadUrl -OutFile $this.InstallerPath -UseBasicParsing
    }

    [void] Install() {
        Write-Host "Installing Bandizip (silent)..." -ForegroundColor Cyan
        $process = Start-Process -FilePath $this.InstallerPath -ArgumentList "/S" -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -ne 0) {
            throw "Bandizip installer exited with code: $($process.ExitCode)"
        }
        Write-Host "Bandizip installed/upgraded successfully!" -ForegroundColor Green
    }

    [void] Cleanup() {
        Remove-Item -Path $this.InstallerPath -Force -ErrorAction SilentlyContinue
    }

    [void] Run() {
        if ($this.IsInstalled() -and -not $this.Force) {
            Write-Host "Bandizip is already installed." -ForegroundColor Green
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
$installer = [BandizipInstaller]::new()
$installer.Force = $Force
$installer.Run()
