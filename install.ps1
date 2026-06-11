#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Uninstall,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$moduleName = 'wux'
$src        = $PSScriptRoot
$moduleBase = ($env:PSModulePath -split ';' | Where-Object { $_ -like '*Documents*' } | Select-Object -First 1)

if (-not $moduleBase) {
    $moduleBase = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules'
}

$dest = Join-Path $moduleBase $moduleName

if ($Uninstall) {
    if (Test-Path $dest) {
        Remove-Item $dest -Recurse -Force
        Write-Host "wux uninstalled from $dest" -ForegroundColor Yellow
    } else {
        Write-Host "wux is not installed at $dest" -ForegroundColor Gray
    }
    # Remove profile line
    if (Test-Path $PROFILE) {
        $lines = Get-Content $PROFILE | Where-Object { $_ -notmatch 'Import-Module wux' }
        $lines | Set-Content $PROFILE
        Write-Host "Removed Import-Module wux from profile." -ForegroundColor Yellow
    }
    return
}

# Install
if (Test-Path $dest) {
    if (-not $Force) {
        $ans = Read-Host "wux is already installed at $dest. Overwrite? [y/N]"
        if ($ans -notmatch '^[Yy]') { Write-Host "Aborted."; return }
    }
    Remove-Item $dest -Recurse -Force
}

Write-Host "Installing wux to $dest ..." -ForegroundColor Cyan
Copy-Item $src $dest -Recurse -Exclude '.git','install.ps1','*.md'

# Ensure profile exists
if (-not (Test-Path $PROFILE)) {
    New-Item $PROFILE -ItemType File -Force | Out-Null
}

$profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
$importLine = "Import-Module $moduleName"

if ($profileContent -notmatch [regex]::Escape($importLine)) {
    Add-Content $PROFILE "`n$importLine"
    Write-Host "Added '$importLine' to $PROFILE" -ForegroundColor Green
} else {
    Write-Host "Profile already imports wux." -ForegroundColor Gray
}

Write-Host @"

  wux installed successfully!
  Commands available after reloading your shell:

    grep   head   tail   sed   awk   find   touch   chmod

  Reload now with:  . `$PROFILE
  Or just open a new PowerShell window.

"@ -ForegroundColor Green
