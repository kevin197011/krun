# Copyright (c) 2026 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Usage:
#   irm https://raw.githubusercontent.com/kevin197011/krun/main/deploy.ps1 | iex
#   powershell -ExecutionPolicy Bypass -File deploy.ps1
#   powershell -ExecutionPolicy Bypass -File deploy.ps1 -Uninstall
#   $env:KRUN_ACTION='uninstall'; irm .../deploy.ps1 | iex
#
# Env:
#   KRUN_VERSION      tag or bare version (v1.0.3 / 1.0.3); default: latest GitHub release
#   KRUN_INSTALL_DIR  install dir (default: %LOCALAPPDATA%\krun\bin)
#   KRUN_REPO         owner/name (default: kevin197011/krun)
#   KRUN_ACTION       install (default) | uninstall

param(
    [switch] $Uninstall,
    [switch] $Install,
    [switch] $Help
)

$ErrorActionPreference = 'Stop'

$Repo = if ($env:KRUN_REPO) { $env:KRUN_REPO } else { 'kevin197011/krun' }
$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) krun-deploy/1.0'
$Action = if ($env:KRUN_ACTION) { $env:KRUN_ACTION.Trim().ToLowerInvariant() } else { 'install' }

if ($Help) {
    Write-Host @'
Usage: deploy.ps1 [-Install] [-Uninstall]
  -Install      install / overwrite-update krun.exe (default)
  -Uninstall    remove krun.exe and User PATH entry we added
Env: KRUN_VERSION KRUN_INSTALL_DIR KRUN_REPO KRUN_ACTION
'@
    return
}
if ($Uninstall) { $Action = 'uninstall' }
if ($Install) { $Action = 'install' }

function Write-Info([string] $Message) {
    Write-Host $Message
}

function Get-KrunArch {
    try {
        $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
        switch ($arch) {
            'x64' { return 'amd64' }
            'arm64' { return 'arm64' }
        }
    } catch { }
    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { return 'arm64' }
    return 'amd64'
}

function Get-KrunTag {
    if ($env:KRUN_VERSION) {
        $v = $env:KRUN_VERSION.Trim()
        if (-not $v.StartsWith('v')) { $v = "v$v" }
        return $v
    }

    $uri = "https://api.github.com/repos/$Repo/releases/latest"
    $headers = @{
        'User-Agent' = $UserAgent
        'Accept'     = 'application/vnd.github+json'
    }
    $release = Invoke-RestMethod -Uri $uri -Headers $headers
    if (-not $release.tag_name) {
        throw 'could not resolve latest release; set $env:KRUN_VERSION = "vX.Y.Z"'
    }
    return [string]$release.tag_name
}

function Get-ExistingExe {
    $candidates = @()
    if ($env:KRUN_INSTALL_DIR) {
        $candidates += (Join-Path $env:KRUN_INSTALL_DIR 'krun.exe')
    }
    $candidates += (Join-Path $env:LOCALAPPDATA 'krun\bin\krun.exe')
    foreach ($path in ($candidates | Select-Object -Unique)) {
        if (Test-Path -LiteralPath $path) {
            return $path
        }
    }
    $cmd = Get-Command krun.exe -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        return $cmd.Source
    }
    return $null
}

function Get-InstallDir {
    if ($env:KRUN_INSTALL_DIR) {
        return $env:KRUN_INSTALL_DIR
    }
    $existing = Get-ExistingExe
    if ($existing) {
        return (Split-Path -Parent $existing)
    }
    return (Join-Path $env:LOCALAPPDATA 'krun\bin')
}

function Get-ExeVersion([string] $Path) {
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) {
        return $null
    }
    try {
        $out = & $Path version 2>$null
        if ($out) {
            return ($out | Select-Object -First 1).ToString().Trim()
        }
    } catch { }
    return $null
}

function Replace-Exe([string] $Source, [string] $Target) {
    # Rename-then-copy so a running krun.exe can still be overwritten on Windows.
    $bak = "$Target.old"
    if (Test-Path -LiteralPath $Target) {
        Remove-Item -LiteralPath $bak -Force -ErrorAction SilentlyContinue
        Move-Item -LiteralPath $Target -Destination $bak -Force
    }
    try {
        Copy-Item -LiteralPath $Source -Destination $Target -Force
    } catch {
        if (Test-Path -LiteralPath $bak) {
            Move-Item -LiteralPath $bak -Destination $Target -Force
        }
        throw
    }
    Remove-Item -LiteralPath $bak -Force -ErrorAction SilentlyContinue
}

function Remove-StaleExe([string] $Keep) {
    $stale = @(
        (Join-Path $env:LOCALAPPDATA 'krun\bin\krun.exe')
    )
    foreach ($path in ($stale | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $path)) { continue }
        if ($path -eq $Keep) { continue }
        Remove-Item -LiteralPath $path -Force
        Write-Info "removed stale $path"
    }
}

function Ensure-UserPath([string] $Dir) {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ([string]::IsNullOrWhiteSpace($userPath)) {
        $userPath = ''
    }
    $parts = @($userPath -split ';' | Where-Object { $_ -and $_.Trim() -ne '' })
    if ($parts -contains $Dir) {
        return
    }
    $newPath = if ($userPath) { "$Dir;$userPath" } else { $Dir }
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    $env:Path = "$Dir;$env:Path"
    Write-Info "added to User PATH: $Dir (open a new terminal if needed)"
}

function Remove-UserPath([string] $Dir) {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ([string]::IsNullOrWhiteSpace($userPath)) {
        return
    }
    $parts = @($userPath -split ';' | Where-Object { $_ -and $_.Trim() -ne '' -and $_ -ne $Dir })
    $newPath = [string]::Join(';', $parts)
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + $newPath
    Write-Info "removed from User PATH: $Dir"
}

function Install-KrunBinary {
    $arch = Get-KrunArch
    $tag = Get-KrunTag
    $ver = $tag.TrimStart('v')
    $zipName = "krun_${ver}_windows_${arch}.zip"
    $url = "https://github.com/$Repo/releases/download/$tag/$zipName"
    $dest = Get-InstallDir

    $existing = Get-ExistingExe
    if ($existing) {
        $cur = Get-ExeVersion $existing
        if ($cur) { Write-Info "found installed krun: $cur" }
        else { Write-Info "found installed krun: $existing" }
    }
    Write-Info "Installing krun $tag (windows/$arch) — will overwrite if present"
    Write-Info "Downloading $zipName ..."

    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("krun-deploy-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        $zipPath = Join-Path $tmp $zipName
        Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing -Headers @{ 'User-Agent' = $UserAgent }

        Expand-Archive -LiteralPath $zipPath -DestinationPath $tmp -Force

        $exe = Get-ChildItem -Path $tmp -Recurse -Filter 'krun.exe' -File | Select-Object -First 1
        if (-not $exe) {
            throw "archive missing krun.exe: $url"
        }

        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        $target = Join-Path $dest 'krun.exe'
        $prev = Get-ExeVersion $target
        if ($prev) {
            Write-Info "updating existing install: $prev → $tag"
        } elseif (Test-Path -LiteralPath $target) {
            Write-Info "replacing existing $target"
        }

        Replace-Exe $exe.FullName $target
        Remove-StaleExe $target
        Ensure-UserPath $dest

        Write-Info "installed $target ($tag, windows/$arch)"
        & $target version
    } finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Uninstall-KrunBinary {
    $dest = Get-InstallDir
    $removed = $false
    $targets = @(
        (Join-Path $dest 'krun.exe'),
        (Join-Path $env:LOCALAPPDATA 'krun\bin\krun.exe')
    ) | Select-Object -Unique

    foreach ($path in $targets) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Force
            Write-Info "removed $path"
            $removed = $true
        }
    }

    Remove-UserPath (Join-Path $env:LOCALAPPDATA 'krun\bin')
    if ($env:KRUN_INSTALL_DIR) {
        Remove-UserPath $env:KRUN_INSTALL_DIR
    }

    $binDir = Join-Path $env:LOCALAPPDATA 'krun\bin'
    $rootDir = Join-Path $env:LOCALAPPDATA 'krun'
    if ((Test-Path -LiteralPath $binDir) -and -not (Get-ChildItem -LiteralPath $binDir -Force -ErrorAction SilentlyContinue)) {
        Remove-Item -LiteralPath $binDir -Force -ErrorAction SilentlyContinue
    }
    if ((Test-Path -LiteralPath $rootDir) -and -not (Get-ChildItem -LiteralPath $rootDir -Force -ErrorAction SilentlyContinue)) {
        Remove-Item -LiteralPath $rootDir -Force -ErrorAction SilentlyContinue
    }

    if (-not $removed) {
        Write-Info 'krun.exe not found in default locations'
    } else {
        Write-Info 'uninstall done'
    }
}

switch ($Action) {
    'uninstall' { Uninstall-KrunBinary }
    'install' { Install-KrunBinary }
    default { throw "unknown KRUN_ACTION=$Action (install|uninstall)" }
}
