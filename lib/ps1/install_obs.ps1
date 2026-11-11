# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Error handling
$ErrorActionPreference = 'Stop'

# Usage:
# powershell -ExecutionPolicy Bypass -File install_obs.ps1
# .\install_obs.ps1
# .\install_obs.ps1 -Force  (force reinstall)
#
# Remote exec:
# irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_obs.ps1 | iex
# $env:FORCE_INSTALL='true'; irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_obs.ps1 | iex

# Description: Install OBS Studio from official installer

# Parse arguments manually for irm | iex support
$Force = $false
if ($args -contains "-Force" -or $args -contains "-force") {
    $Force = $true
}

if ($env:FORCE_INSTALL -eq 'true') {
    $Force = $true
}

class OBSInstaller {
    [string] $GitHubRepo = "obsproject/obs-studio"
    [string] $InstallDir = "$env:ProgramFiles\obs-studio"
    [string] $Version
    [string] $DownloadUrl
    [string] $InstallerPath
    [bool] $Force = $false

    [void] FetchLatestVersion() {
        Write-Host "Fetching latest OBS Studio version from GitHub..." -ForegroundColor Cyan
        $apiUrl = "https://api.github.com/repos/$($this.GitHubRepo)/releases/latest"
        $ProgressPreference = 'SilentlyContinue'
        try {
            $response = Invoke-WebRequest -Uri $apiUrl -UseBasicParsing | ConvertFrom-Json
            $this.Version = $response.tag_name.TrimStart('v')
            
            # Find the Windows x64 Installer in the assets
            $asset = $response.assets | Where-Object { $_.name -like "OBS-Studio-*-Windows-x64-Installer.exe" } | Select-Object -First 1
            if ($null -eq $asset) {
                throw "Could not find Windows x64 installer in GitHub releases."
            }
            $this.DownloadUrl = $asset.browser_download_url
            $this.InstallerPath = "$env:TEMP\$($asset.name)"
            Write-Host "Latest version: $($this.Version)" -ForegroundColor Green
        } catch {
            Write-Host "Failed to fetch latest version from GitHub. Falling back to default URL." -ForegroundColor Yellow
            $this.Version = "32.0.4"
            $this.DownloadUrl = "https://cdn-fastly.obsproject.com/downloads/OBS-Studio-32.0.4-Windows-x64-Installer.exe"
            $this.InstallerPath = "$env:TEMP\OBS-Studio-32.0.4-Windows-x64-Installer.exe"
        }
    }

    [bool] IsInstalled() {
        $exePath = Join-Path $this.InstallDir "bin\64bit\obs64.exe"
        if (Test-Path -Path $exePath) {
            return $true
        }
        return $false
    }

    [void] Download() {
        Write-Host "Downloading OBS Studio installer from $($this.DownloadUrl)..." -ForegroundColor Cyan
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $this.DownloadUrl `
            -OutFile $this.InstallerPath `
            -UseBasicParsing `
            -TimeoutSec 600 `
            -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    }

    [void] Install() {
        Write-Host "Installing OBS Studio (silent)..." -ForegroundColor Cyan
        # /S = silent mode
        # /D = installation directory (must be last parameter for NSIS and without quotes)
        $process = Start-Process -FilePath $this.InstallerPath -ArgumentList "/S", "/D=$($this.InstallDir)" -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -ne 0) {
            throw "OBS Studio installer exited with code: $($process.ExitCode)"
        }
        Write-Host "OBS Studio installed successfully!" -ForegroundColor Green
    }

    [void] Cleanup() {
        if (Test-Path $this.InstallerPath) {
            Remove-Item -Path $this.InstallerPath -Force -ErrorAction SilentlyContinue
        }
    }

    [void] Run() {
        $this.FetchLatestVersion()

        if ($this.IsInstalled() -and -not $this.Force) {
            Write-Host "OBS Studio is already installed at: $($this.InstallDir)" -ForegroundColor Green
            Write-Host "Skipping installation. Use -Force parameter to force reinstall." -ForegroundColor Yellow
            return
        }
        
        if ($this.Force -and $this.IsInstalled()) {
            Write-Host "Force flag detected. Proceeding with reinstall..." -ForegroundColor Yellow
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
$installer = [OBSInstaller]::new()
$installer.Force = $Force
$installer.Run()
