# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Error handling
$ErrorActionPreference = 'Stop'

# Usage:
# powershell -ExecutionPolicy Bypass -File install_caddy.ps1
# .\install_caddy.ps1
# .\install_caddy.ps1 -Force  (force reinstall)
#
# Remote exec:
# irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_caddy.ps1 | iex
# $env:FORCE_INSTALL='true'; irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_caddy.ps1 | iex

# Description: Install or upgrade Caddy Web Server (official binary)

# Parse arguments manually for irm | iex support
$Force = $false
if ($args -contains "-Force" -or $args -contains "-force") {
    $Force = $true
}

if ($env:FORCE_INSTALL -eq 'true') {
    $Force = $true
}

class CaddyInstaller {
    [string] $DownloadUrl = "https://caddyserver.com/api/download?os=windows&arch=amd64"
    [string] $TempPath = "$env:TEMP\caddy.exe"
    [string] $InstallDir = "$env:ProgramFiles\Caddy"
    [bool] $Force = $false

    [bool] IsInstalled() {
        if (Test-Path -Path "$($this.InstallDir)\caddy.exe") {
            return $true
        }
        # Check if caddy is in path
        if (Get-Command "caddy" -ErrorAction SilentlyContinue) {
            return $true
        }
        return $false
    }

    [void] Download() {
        Write-Host "Downloading Caddy binary..." -ForegroundColor Cyan
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $this.DownloadUrl -OutFile $this.TempPath -UseBasicParsing
    }

    [void] Install() {
        Write-Host "Installing Caddy..." -ForegroundColor Cyan
        
        # Create Install Directory
        if (-not (Test-Path $this.InstallDir)) {
            New-Item -ItemType Directory -Force -Path $this.InstallDir | Out-Null
        }

        # Backup existing if present (optional, but good for safety? usually just overwrite)
        # We will just overwrite with Move-Item -Force
        
        Move-Item -Path $this.TempPath -Destination "$($this.InstallDir)\caddy.exe" -Force

        # Run version check to verify binary works
        Write-Host "Verifying binary..." -ForegroundColor Cyan
        & "$($this.InstallDir)\caddy.exe" version

        # Add to PATH if not present
        $this.AddToPath()

        Write-Host "Caddy installed/upgraded successfully!" -ForegroundColor Green
    }

    [void] AddToPath() {
        $scope = "Machine"
        $currentPath = [Environment]::GetEnvironmentVariable("Path", $scope)

        # Normalize paths for comparison (remove trailing slashes, case insensitive check)
        # Simple check
        if ($currentPath -notlike "*$($this.InstallDir)*") {
            Write-Host "Adding Caddy to System PATH..." -ForegroundColor Cyan
            try {
                $newPath = "$currentPath;$($this.InstallDir)"
                [Environment]::SetEnvironmentVariable("Path", $newPath, $scope)
                Write-Host "Path updated. You may need to restart your shell." -ForegroundColor Yellow
            } catch {
                Write-Host "Failed to update System Path. Please run as Administrator or add '$($this.InstallDir)' to PATH manually." -ForegroundColor Red
            }
        } else {
            Write-Host "Caddy is already in System PATH." -ForegroundColor Gray
        }
    }

    [void] Cleanup() {
        if (Test-Path $this.TempPath) {
            Remove-Item -Path $this.TempPath -Force -ErrorAction SilentlyContinue
        }
    }

    [void] Run() {
        if ($this.IsInstalled() -and -not $this.Force) {
            Write-Host "Caddy is already installed." -ForegroundColor Green
            Write-Host "Skipping installation. Use -Force to force reinstall/upgrade." -ForegroundColor Yellow
            return
        }
        
        $this.Download()
        try {
            $this.Install()
        } catch {
            throw $_
        } finally {
            $this.Cleanup()
        }
    }
}

# Main execution
$installer = [CaddyInstaller]::new()
$installer.Force = $Force
$installer.Run()
