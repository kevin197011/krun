# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Error handling
$ErrorActionPreference = 'Stop'

# Usage:
# powershell -ExecutionPolicy Bypass -File config_timezone_utc8_ntp.ps1
# .\config_timezone_utc8_ntp.ps1
#
# Remote exec:
# irm https://raw.githubusercontent.com/kevin197011/krun/main/lib/ps1/config_timezone_utc8_ntp.ps1 | iex
#
# Note: Setting timezone and NTP config may require running as Administrator.

# Description: Set timezone to China Standard Time (UTC+8, 东八区) and sync time via NTP

class TimeZoneNtpSetter {
    [string] $TimeZoneId = "China Standard Time"
    [string[]] $NtpServers = @("time.windows.com", "ntp.aliyun.com")

    [bool] IsAdmin() {
        $currentPrincipal = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
        return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    [string] GetCurrentTimeZone() {
        return (Get-TimeZone).Id
    }

    [void] SetTimeZone() {
        if ((Get-TimeZone).Id -eq $this.TimeZoneId) {
            Write-Host "Timezone is already $($this.TimeZoneId) (UTC+8)." -ForegroundColor Green
            return
        }
        Write-Host "Setting timezone to $($this.TimeZoneId) (东八区)..." -ForegroundColor Cyan
        Set-TimeZone -Id $this.TimeZoneId
        Write-Host "Timezone set successfully." -ForegroundColor Green
    }

    [void] EnsureTimeServiceRunning() {
        $svc = Get-Service -Name "W32Time" -ErrorAction SilentlyContinue
        if (-not $svc) {
            throw "Windows Time service (W32Time) not found."
        }
        if ($svc.Status -ne "Running") {
            Write-Host "Starting Windows Time service..." -ForegroundColor Cyan
            Start-Service -Name "W32Time"
        }
    }

    [void] ConfigureNtp() {
        $peerList = $this.NtpServers -join " "
        Write-Host "Configuring NTP peers: $($this.NtpServers -join ', ')" -ForegroundColor Cyan
        & w32tm /config "/manualpeerlist:$peerList" /syncfromflags:manual /reliable:YES /update
        if ($LASTEXITCODE -ne 0) {
            throw "w32tm config failed with exit code $LASTEXITCODE"
        }
        Write-Host "NTP configuration updated." -ForegroundColor Green
    }

    [void] ResyncTime() {
        Write-Host "Syncing time with NTP server..." -ForegroundColor Cyan
        & w32tm /resync
        if ($LASTEXITCODE -ne 0) {
            Write-Host "w32tm /resync returned $LASTEXITCODE (time may still sync in background)." -ForegroundColor Yellow
        } else {
            Write-Host "Time synced successfully." -ForegroundColor Green
        }
    }

    [void] Run() {
        if (-not $this.IsAdmin()) {
            Write-Host "Warning: Not running as Administrator. Timezone change and NTP config may fail." -ForegroundColor Yellow
        }
        $this.SetTimeZone()
        $this.EnsureTimeServiceRunning()
        $this.ConfigureNtp()
        $this.ResyncTime()
        Write-Host "Done. Current time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')" -ForegroundColor Green
    }
}

# Main execution
$setter = [TimeZoneNtpSetter]::new()
$setter.Run()
