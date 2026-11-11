# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Error handling
$ErrorActionPreference = 'Stop'

# Usage:
# powershell -ExecutionPolicy Bypass -File install_winget.ps1
# Or in PowerShell:
# .\install_winget.ps1

# Remote exec:
# powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_winget.ps1').Content"
# Or shorter:
# irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_winget.ps1 | iex

# Description: Install or upgrade winget (Windows Package Manager) from GitHub release

class WingetInstaller {
    [string] $DownloadUrl
    [string] $DependenciesZipUrl
    [string] $InstallerPath
    [string] $DependenciesZipPath = "$env:TEMP\winget-dependencies.zip"
    [string] $DependenciesExtractPath = "$env:TEMP\winget-dependencies"

    WingetInstaller() {
        $this.InstallerPath = "$env:TEMP\winget.msixbundle"
    }

    [void] GetDownloadUrls() {
        # Use v1.11.x to avoid Windows App Runtime 1.8 dependency issues
        $tagsToTry = @("v1.11.510", "v1.11.400")
        $release = $null
        foreach ($tag in $tagsToTry) {
            try {
                Write-Host "Fetching winget release $tag..." -ForegroundColor Cyan
                $release = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/winget-cli/releases/tags/$tag"
                break
            } catch {
                Write-Host "  $tag not found, trying next..."
            }
        }
        if (-not $release) {
            Write-Host "Fallback: using latest release..." -ForegroundColor Yellow
            $release = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
        }
        
        $this.DownloadUrl = $release.assets | Where-Object { $_.name -like "*.msixbundle" } | Select-Object -ExpandProperty browser_download_url -First 1
        if (-not $this.DownloadUrl) {
            throw "Failed to find winget installer (.msixbundle) in release"
        }
        $this.DependenciesZipUrl = $null
        $depAsset = $release.assets | Where-Object { $_.name -like "*Dependencies*.zip" } | Select-Object -First 1
        if ($depAsset) {
            $this.DependenciesZipUrl = $depAsset.browser_download_url
            Write-Host "Found dependencies: $($depAsset.name)" -ForegroundColor Green
        }
    }

    [void] DownloadInstaller() {
        Write-Host "Downloading winget installer..."
        Invoke-WebRequest -Uri $this.DownloadUrl -OutFile $this.InstallerPath -UseBasicParsing
        if ($this.DependenciesZipUrl) {
            Write-Host "Downloading dependencies..."
            Invoke-WebRequest -Uri $this.DependenciesZipUrl -OutFile $this.DependenciesZipPath -UseBasicParsing
            Write-Host "Extracting dependencies..."
            if (Test-Path $this.DependenciesExtractPath) {
                Remove-Item -Path $this.DependenciesExtractPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            Expand-Archive -Path $this.DependenciesZipPath -DestinationPath $this.DependenciesExtractPath -Force
        }
    }

    [string[]] GetDependencyPaths() {
        # Detect current system architecture
        $currentArch = $env:PROCESSOR_ARCHITECTURE.ToLower()
        if ($currentArch -eq "amd64") { $currentArch = "x64" }
        
        Write-Host "Detected architecture: $currentArch. Filtering matching dependency files..." -ForegroundColor Cyan

        # Get all extracted dependency files
        $allFiles = Get-ChildItem -Path $this.DependenciesExtractPath -Recurse -Include "*.msix", "*.appx" -ErrorAction SilentlyContinue
        
        # Filter: match current arch (x64/arm64) or neutral; exclude mismatched packages (avoids 0x80073D10)
        $filtered = $allFiles | Where-Object {
            $fileName = $_.Name.ToLower()
            $isMatch = ($fileName -like "*$currentArch*") -or ($fileName -like "*neutral*")
            
            if ($currentArch -eq "x64") {
                $isMatch = $isMatch -and ($fileName -notlike "*arm*")
            }
            if ($currentArch -eq "arm64") {
                $isMatch = $isMatch -and ($fileName -notlike "*x86*") -and ($fileName -notlike "*x64*")
            }
            
            return $isMatch
        }

        $paths = $filtered | Select-Object -ExpandProperty FullName
        foreach ($p in $paths) {
            Write-Host "  + Dependency to install: $(Split-Path $p -Leaf)" -ForegroundColor Gray
        }
        return $paths
    }

    [void] Install() {
        Write-Host "Installing/upgrading winget..." -ForegroundColor Cyan
        
        $depPaths = @()
        if ($this.DependenciesZipUrl -and (Test-Path $this.DependenciesExtractPath)) {
            $depPaths = $this.GetDependencyPaths()
        }

        try {
            if ($depPaths.Count -gt 0) {
                Write-Host "Installing main package with $($depPaths.Count) dependency package(s)..." -ForegroundColor Green
                Add-AppxPackage -Path $this.InstallerPath -DependencyPath $depPaths -ForceApplicationShutdown -ForceUpdateFromAnyVersion
            } else {
                Write-Host "Installing main package (no extra dependencies)..."
                Add-AppxPackage -Path $this.InstallerPath -ForceApplicationShutdown -ForceUpdateFromAnyVersion
            }
        } catch {
            Write-Host "Installation failed. Error details:" -ForegroundColor Red
            Write-Host $_.Exception.Message
            throw
        }
        
        Write-Host "Winget installed/upgraded successfully!" -ForegroundColor Green
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        Start-Sleep -Seconds 2
        
        # Verify
        $wingetPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
        if (Test-Path $wingetPath) {
            Write-Host "✓ Winget executable at: $wingetPath"
            try {
                $v = & $wingetPath --version
                Write-Host "✓ Version check OK: $v" -ForegroundColor Green
            } catch {}
        }
    }

    [void] Cleanup() {
        Write-Host "Cleaning up temporary files..." -ForegroundColor Gray
        if (Test-Path $this.InstallerPath) { Remove-Item $this.InstallerPath -Force }
        if (Test-Path $this.DependenciesZipPath) { Remove-Item $this.DependenciesZipPath -Force }
        if (Test-Path $this.DependenciesExtractPath) { Remove-Item $this.DependenciesExtractPath -Recurse -Force }
    }

    [void] Run() {
        try {
            $this.GetDownloadUrls()
            $this.DownloadInstaller()
            $this.Install()
        }
        finally {
            $this.Cleanup()
        }
    }
}

# Main execution
$installer = [WingetInstaller]::new()
$installer.Run()