# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Error handling
$ErrorActionPreference = 'Stop'

# Usage:
# powershell -ExecutionPolicy Bypass -File install_vscode.ps1
# .\install_vscode.ps1
# .\install_vscode.ps1 -Force  (force reinstall)
#
# Remote exec:
# irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_vscode.ps1 | iex
# $env:FORCE_INSTALL='true'; irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_vscode.ps1 | iex

# Description: Install or upgrade Microsoft Visual Studio Code (System Installer)

# Parse arguments manually for irm | iex support
$Force = $false
if ($args -contains "-Force" -or $args -contains "-force") {
    $Force = $true
}

if ($env:FORCE_INSTALL -eq 'true') {
    $Force = $true
}

class VSCodeInstaller {
    # System Installer (install for all users)
    [string] $DownloadUrl = "https://update.code.visualstudio.com/latest/win32-x64/stable"
    [string] $InstallerPath = "$env:TEMP\VSCodeSetup-x64.exe"
    [string] $InstallDir = "$env:ProgramFiles\Microsoft VS Code"
    [bool] $Force = $false

    [bool] IsInstalled() {
        if (Test-Path -Path "$($this.InstallDir)\Code.exe") {
            return $true
        }
        return $false
    }

    [void] Download() {
        Write-Host "Downloading VS Code System Installer..." -ForegroundColor Cyan
        $ProgressPreference = 'SilentlyContinue'
        try {
            Invoke-WebRequest -Uri $this.DownloadUrl -OutFile $this.InstallerPath -UseBasicParsing
        } catch {
            throw "Failed to download VS Code installer: $_"
        }
    }

    [void] Install() {
        Write-Host "Installing VS Code (silent)..." -ForegroundColor Cyan
        
        # Inno Setup arguments
        # /VERYSILENT /NORESTART
        # /MERGETASKS="!runcode,desktopicon,quicklaunchicon,addcontextmenufiles,addcontextmenufolders,addtopath"
        # !runcode means do NOT run code after install
        
        $argsList = "/VERYSILENT", "/NORESTART", "/MERGETASKS=`"!runcode,desktopicon,addcontextmenufiles,addcontextmenufolders,addtopath`""
        
        $process = Start-Process -FilePath $this.InstallerPath -ArgumentList $argsList -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -ne 0) {
            throw "VS Code installer exited with code: $($process.ExitCode)"
        }
        
        Write-Host "VS Code installed/upgraded successfully!" -ForegroundColor Green
    }

    [void] Cleanup() {
        if (Test-Path $this.InstallerPath) {
            Remove-Item -Path $this.InstallerPath -Force -ErrorAction SilentlyContinue
        }
    }

    [void] Run() {
        if ($this.IsInstalled() -and -not $this.Force) {
            Write-Host "VS Code is already installed at: $($this.InstallDir)" -ForegroundColor Green
            Write-Host "Skipping installation. Use -Force to force reinstall." -ForegroundColor Yellow
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
$installer = [VSCodeInstaller]::new()
$installer.Force = $Force
$installer.Run()
