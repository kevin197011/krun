# Copyright (c) 2026 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Error handling
$ErrorActionPreference = 'Stop'

# Usage:
# powershell -ExecutionPolicy Bypass -File disable_firewall.ps1
# .\disable_firewall.ps1
#
# Remote exec:
# irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/disable_firewall.ps1 | iex
#
# Note: Requires Administrator. Disables Windows Defender Firewall for Domain, Private, and Public profiles.

# Description: Disable Windows Firewall on all profiles (Domain / Private / Public)

class FirewallDisabler {
    [string[]] $Profiles = @("Domain", "Private", "Public")

    [bool] IsAdmin() {
        $currentPrincipal = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
        return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    [object[]] GetProfiles() {
        if (Get-Command Get-NetFirewallProfile -ErrorAction SilentlyContinue) {
            return @(Get-NetFirewallProfile -Profile Domain, Private, Public)
        }
        return @()
    }

    [bool] AllDisabled() {
        $profiles = $this.GetProfiles()
        if ($profiles.Count -eq 0) {
            return $false
        }
        foreach ($p in $profiles) {
            if ($p.Enabled) {
                return $false
            }
        }
        return $true
    }

    [void] ShowStatus() {
        Write-Host "Current firewall profile status:" -ForegroundColor Cyan
        $profiles = $this.GetProfiles()
        if ($profiles.Count -gt 0) {
            foreach ($p in $profiles) {
                $state = if ($p.Enabled) { "ON" } else { "OFF" }
                $color = if ($p.Enabled) { "Yellow" } else { "Green" }
                Write-Host ("  {0,-8} : {1}" -f $p.Name, $state) -ForegroundColor $color
            }
            return
        }

        # Fallback status via netsh
        & netsh advfirewall show allprofiles state
    }

    [void] DisableViaCmdlet() {
        Write-Host "Disabling Windows Firewall (Domain, Private, Public)..." -ForegroundColor Cyan
        Set-NetFirewallProfile -Profile Domain, Private, Public -Enabled False
    }

    [void] DisableViaNetsh() {
        Write-Host "Disabling Windows Firewall via netsh (all profiles)..." -ForegroundColor Cyan
        & netsh advfirewall set allprofiles state off
        if ($LASTEXITCODE -ne 0) {
            throw "netsh advfirewall set allprofiles state off failed with exit code $LASTEXITCODE"
        }
    }

    [void] Run() {
        if (-not $this.IsAdmin()) {
            throw "Administrator privileges required. Re-run PowerShell as Administrator."
        }

        if ($this.AllDisabled()) {
            Write-Host "Windows Firewall is already disabled on all profiles." -ForegroundColor Green
            $this.ShowStatus()
            return
        }

        if (Get-Command Set-NetFirewallProfile -ErrorAction SilentlyContinue) {
            $this.DisableViaCmdlet()
        } else {
            $this.DisableViaNetsh()
        }

        Write-Host "Windows Firewall disabled on all profiles." -ForegroundColor Green
        $this.ShowStatus()
    }
}

# Main execution
$disabler = [FirewallDisabler]::new()
$disabler.Run()
