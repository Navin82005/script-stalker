<#
.SYNOPSIS
  Installs every Bash script found in scripts\ as a command on Windows,
  removing the .sh extension from the installed command name.

.DESCRIPTION
  These tools are Bash scripts, so Windows needs a Bash interpreter to run them.
  This installer looks for one, in order:
    1. Git Bash
    2. WSL

  It scans the scripts\ folder next to this installer, and for every file whose
  first line is a Bash shebang (e.g. "#!/bin/bash" or "#!/usr/bin/env bash"),
  copies it and generates a matching .cmd shim in an install folder.

  The .sh extension is removed from the command name.

  Example:
    scripts\broom.sh  ->  broom
    scripts\ftree.sh  ->  ftree

.USAGE
  Right-click this file -> "Run with PowerShell"
  -- or --
  Open PowerShell in this folder and run:
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
    .\install-windows.ps1
#>

$ErrorActionPreference = "Stop"

$ScriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptsSrcDir = Join-Path $ScriptDir "scripts"
$InstallDir    = Join-Path $env:USERPROFILE "bin"

if (-not (Test-Path $ScriptsSrcDir)) {
    Write-Host "No 'scripts' folder found next to this installer: $ScriptsSrcDir" -ForegroundColor Red
    exit 1
}

# A file counts as a Bash script if its first line is a bash shebang,
# e.g. "#!/bin/bash" or "#!/usr/bin/env bash".
function Test-IsBashScript {
    param([string]$Path)

    $firstLine = Get-Content -Path $Path -TotalCount 1 -ErrorAction SilentlyContinue

    if (-not $firstLine) {
        return $false
    }

    return $firstLine -match '^\#\!.*[/ ]bash(\s|$)'
}

# Keep both the original source filename and the command name.
$Tools = Get-ChildItem -Path $ScriptsSrcDir -File |
    Where-Object {
        Test-IsBashScript -Path $_.FullName
    } |
    ForEach-Object {
        [PSCustomObject]@{
            SourceName = $_.Name
            CommandName = if ($_.Name -match '\.sh$') {
                $_.Name.Substring(0, $_.Name.Length - 3)
            } else {
                $_.Name
            }
        }
    }

if (-not $Tools -or $Tools.Count -eq 0) {
    Write-Host "No Bash scripts found in $ScriptsSrcDir" -ForegroundColor Red
    exit 1
}

Write-Host "Found $($Tools.Count) Bash script(s): $($Tools.CommandName -join ', ')"
Write-Host "Installing CLI tools to: $InstallDir"

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

# ─────────────────────────────────────────────
# Locate a Bash interpreter
# ─────────────────────────────────────────────

$GitBashPaths = @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "$env:LocalAppData\Programs\Git\bin\bash.exe"
)

$BashMode = $null
$BashExe  = $null

foreach ($path in $GitBashPaths) {
    if (Test-Path $path) {
        $BashMode = "gitbash"
        $BashExe  = $path
        break
    }
}

if (-not $BashMode) {
    $gitBashOnPath = Get-Command bash.exe -ErrorAction SilentlyContinue

    if ($gitBashOnPath) {
        $BashMode = "gitbash"
        $BashExe  = $gitBashOnPath.Source
    }
}

if (-not $BashMode) {
    $wsl = Get-Command wsl.exe -ErrorAction SilentlyContinue

    if ($wsl) {
        try {
            wsl.exe -- echo ok 2>$null | Out-Null
            $BashMode = "wsl"
        } catch {
            $BashMode = $null
        }
    }
}

if (-not $BashMode) {
    Write-Host ""
    Write-Host "No Bash interpreter found." -ForegroundColor Yellow
    Write-Host "Install one of the following, then re-run this installer:"
    Write-Host "  - Git for Windows (recommended): https://git-scm.com/download/win"
    Write-Host "  - WSL: run 'wsl --install' in an elevated PowerShell"
    exit 1
}

Write-Host "Found Bash via: $BashMode"

# ─────────────────────────────────────────────
# Copy the actual scripts
# ─────────────────────────────────────────────

foreach ($tool in $Tools) {
    $src  = Join-Path $ScriptsSrcDir $tool.SourceName
    $dest = Join-Path $InstallDir $tool.CommandName

    if (-not (Test-Path $src)) {
        Write-Host "Missing source file: $src" -ForegroundColor Red
        exit 1
    }

    Copy-Item -Path $src -Destination $dest -Force

    Write-Host "Installed script: $dest"
}

# ─────────────────────────────────────────────
# Generate .cmd shims
# ─────────────────────────────────────────────

foreach ($tool in $Tools) {
    $scriptPath = Join-Path $InstallDir $tool.CommandName
    $cmdPath    = Join-Path $InstallDir "$($tool.CommandName).cmd"

    if ($BashMode -eq "gitbash") {
        # Git Bash understands Windows-style paths directly.
        $shim = "@echo off`r`n`"$BashExe`" `"$scriptPath`" %*`r`n"
    } else {
        # WSL's interop layer translates the Windows path automatically.
        $shim = "@echo off`r`nwsl.exe `"$scriptPath`" %*`r`n"
    }

    Set-Content -Path $cmdPath -Value $shim -Encoding ASCII

    Write-Host "Created shim: $cmdPath"
}

# ─────────────────────────────────────────────
# Add InstallDir to user PATH
# ─────────────────────────────────────────────

$CurrentPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($CurrentPath -notlike "*$InstallDir*") {
    $NewPath = if ([string]::IsNullOrEmpty($CurrentPath)) {
        $InstallDir
    } else {
        "$CurrentPath;$InstallDir"
    }

    [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")

    Write-Host ""
    Write-Host "Added $InstallDir to your user PATH." -ForegroundColor Green
    Write-Host "Open a NEW terminal window for this to take effect."
} else {
    Write-Host ""
    Write-Host "$InstallDir is already on your PATH."
}

Write-Host ""
Write-Host "Done. Installed commands:" -ForegroundColor Cyan

foreach ($tool in $Tools) {
    Write-Host "   $($tool.CommandName)"
}