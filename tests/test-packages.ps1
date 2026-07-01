<#
.SYNOPSIS
    WinGet Package Validation Dry-Run (Dynamic Config Selector)
#>
param (
    [string]$Path
)

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Add-Type -AssemblyName System.Windows.Forms

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "    WINCONFIG PACKAGE VALIDATION TEST    " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$ConfigFile = $Path

# 1. Dynamic File Selector (If no path was explicitly passed as an argument)
if ([string]::IsNullOrEmpty($ConfigFile)) {
    if ([Environment]::UserInteractive) {
        Write-Host "[*] Opening file explorer to select profile..." -ForegroundColor Yellow
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
        $FileBrowser.InitialDirectory = $ScriptRoot
        $FileBrowser.Filter = "PowerShell Data Files (*.psd1)|*.psd1"
        $FileBrowser.Title = "Select a Configuration Profile to Validate"
        
        $Null = $FileBrowser.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost=$true}))
        $ConfigFile = $FileBrowser.FileName
    }

    # Fallback to CLI list if GUI dialog was cancelled or unavailable
    if ([string]::IsNullOrEmpty($ConfigFile)) {
        Write-Host "[!] No file chosen via GUI. Scanning script directory..." -ForegroundColor Yellow
        $AvailableConfigs = Get-ChildItem -Path $ScriptRoot -Filter *.psd1
        
        if ($AvailableConfigs.Count -eq 0) {
            Write-Error "No .psd1 configuration files found in $ScriptRoot"
            Exit
        }

        Write-Host "`nAvailable Profiles for Testing:"
        for ($i = 0; $i -lt $AvailableConfigs.Count; $i++) {
            Write-Host ("{0}) {1}" -f ($i + 1), $AvailableConfigs[$i].Name)
        }

        do {
            $Selection = Read-Host "`nChoose a profile configuration number"
            $Index = [int]$Selection - 1
        } while ($Selection -notmatch '^\d+$' -or $Index -lt 0 -or $Index -ge $AvailableConfigs.Count)

        $ConfigFile = $AvailableConfigs[$Index].FullName
    }
}

# 2. Safety Check
if (-not (Test-Path $ConfigFile)) {
    Write-Error "Configuration file not found: $ConfigFile"
    Exit
}

# 3. Dynamic Parsing of the Data File
Write-Host "`n[+] Parsing data structure: $(Split-Path $ConfigFile -Leaf)" -ForegroundColor Green
$Config = Import-PowerShellDataFile $ConfigFile
$Apps = $Config.WingetApps

if (-not $Apps) {
    Write-Warning "No 'WingetApps' array detected inside this configuration file."
    Exit
}

Write-Host "Testing $($Apps.Count) app manifests against the upstream repository...`n"

$FailedApps = @()
$Count = 0

foreach ($App in $Apps) {
    $Count++
    Write-Host ("[{0}/{1}] Checking: {2} " -f $Count, $Apps.Count, $App.PadRight(40)) -NoNewline
    
    # Fast network check against the upstream repository index
    $null = winget show --id $App --exact 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[ PASS ]" -ForegroundColor Green
    } else {
        Write-Host "[ FAIL ]" -ForegroundColor Red
        $FailedApps += $App
    }
}

Write-Host "`n=========================================" -ForegroundColor Cyan
if ($FailedApps.Count -eq 0) {
    Write-Host "[+] Dry run complete! All package IDs in this file are valid and live upstream." -ForegroundColor Green
} else {
    Write-Warning "[!] Validation failed for $($FailedApps.Count) package manifest(s):"
    foreach ($Failed in $FailedApps) {
        Write-Host "  -> $Failed" -ForegroundColor Yellow
    }
}