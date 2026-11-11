# Copyright (c) 2026 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Error handling: fail-fast (first script failure stops the run)
$ErrorActionPreference = 'Stop'

# Usage (from a checkout of lib/ps1, or when krun extracts this file alone
# prefer: krun install_windows_all.ps1 — CLI runs every embedded install_*.ps1):
#   powershell -ExecutionPolicy Bypass -File install_windows_all.ps1
#   .\install_windows_all.ps1 -Force

# Description: Run all install_*.ps1 in this directory (skips self). No manifest / no network.

$Force = $false
if ($args -contains "-Force" -or $args -contains "-force") {
    $Force = $true
}
if ($env:FORCE_INSTALL -eq 'true') {
    $Force = $true
}

$root = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($root)) {
    $root = Get-Location | Select-Object -ExpandProperty Path
}

$scripts = @(
    Get-ChildItem -LiteralPath $root -Filter 'install_*.ps1' -File |
        Where-Object { $_.Name -ne 'install_windows_all.ps1' } |
        Sort-Object Name |
        ForEach-Object { $_.FullName }
)

if ($scripts.Count -eq 0) {
    Write-Host "No install_*.ps1 found in $root" -ForegroundColor Yellow
    Write-Host "Tip: use the krun binary: krun install_windows_all.ps1" -ForegroundColor Cyan
    exit 0
}

Write-Host "Found $($scripts.Count) Windows install scripts in $root" -ForegroundColor Green
foreach ($path in $scripts) {
    $name = Split-Path -Leaf $path
    Write-Host "Running $name ..." -ForegroundColor Cyan
    if ($Force) {
        & powershell -ExecutionPolicy Bypass -File $path -Force
    } else {
        & powershell -ExecutionPolicy Bypass -File $path
    }
    if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
        throw "Script $name exited with code $LASTEXITCODE"
    }
}
Write-Host "All Windows install scripts completed successfully." -ForegroundColor Green
