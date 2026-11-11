# Copyright (c) 2026 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Error handling: fail-fast (first script failure stops the run)
$ErrorActionPreference = 'Stop'

# Usage:
# Local:
#   powershell -ExecutionPolicy Bypass -File install_windows_all.ps1
#   .\install_windows_all.ps1
#   .\install_windows_all.ps1 -Force
#
# Remote:
#   irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_windows_all.ps1 | iex
#   $env:FORCE_INSTALL='true'; irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/install_windows_all.ps1 | iex

# Description: Run all Windows install scripts listed under meta/lib-manifest.json → ps1
# (skips install_windows_all.ps1 itself and config_* scripts)

$Force = $false
if ($args -contains "-Force" -or $args -contains "-force") {
    $Force = $true
}
if ($env:FORCE_INSTALL -eq 'true') {
    $Force = $true
}

class ScriptRunner {
    [string] $BaseUrl = "https://raw.githubusercontent.com/kevin197011/krun/main"
    [string] $ManifestUrl
    [array] $Scripts
    [bool] $Force = $false

    ScriptRunner() {
        $this.ManifestUrl = "$($this.BaseUrl)/meta/lib-manifest.json"
    }

    [void] LoadManifest() {
        Write-Host "Loading manifest from $($this.ManifestUrl)..." -ForegroundColor Cyan
        $manifest = Invoke-WebRequest -Uri $this.ManifestUrl -UseBasicParsing | ConvertFrom-Json
        $files = @()
        if ($manifest.ps1) {
            $files = @($manifest.ps1)
        } elseif ($manifest.files) {
            $files = @($manifest.files)
        }
        $this.Scripts = @(
            $files | Where-Object {
                $_ -like "install_*.ps1" -and $_ -ne "install_windows_all.ps1"
            }
        )
        Write-Host "Found $($this.Scripts.Count) Windows install scripts to run." -ForegroundColor Green
    }

    [void] RunScript([string] $ScriptName) {
        $local = Join-Path $PSScriptRoot $ScriptName
        if (Test-Path -LiteralPath $local) {
            Write-Host "Running $ScriptName (local) ..." -ForegroundColor Cyan
            if ($this.Force) {
                & powershell -ExecutionPolicy Bypass -File $local -Force
            } else {
                & powershell -ExecutionPolicy Bypass -File $local
            }
            if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
                throw "Script $ScriptName exited with code $LASTEXITCODE"
            }
            return
        }

        $url = "$($this.BaseUrl)/lib/ps1/$ScriptName"
        Write-Host "Running $ScriptName ..." -ForegroundColor Cyan
        try {
            $scriptContent = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
            if ($this.Force) {
                Write-Host "  (Force mode enabled)" -ForegroundColor Yellow
                Invoke-Expression "$scriptContent -Force"
            } else {
                Invoke-Expression $scriptContent
            }
        } catch {
            Write-Host "Error running $ScriptName : $_" -ForegroundColor Red
            throw
        }
    }

    [void] RunAll() {
        $this.LoadManifest()
        foreach ($script in $this.Scripts) {
            $this.RunScript($script)
        }
        Write-Host "All Windows install scripts completed successfully." -ForegroundColor Green
    }
}

$runner = [ScriptRunner]::new()
$runner.Force = $Force
$runner.RunAll()
