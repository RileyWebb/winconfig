<#
.SYNOPSIS
    VSCode Extension Validation Dry-Run
.DESCRIPTION
    Validates extension marketplace IDs against the live Microsoft API.
#>
param (
    [string]$Path
)

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Add-Type -AssemblyName System.Windows.Forms

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "    VSCODE EXTENSION VALIDATION TEST     " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$ConfigFile = $Path

# 1. Profile Selection Logic
if ([string]::IsNullOrEmpty($ConfigFile)) {
    if ([Environment]::UserInteractive) {
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
        $FileBrowser.InitialDirectory = $ScriptRoot
        $FileBrowser.Filter = "PowerShell Data Files (*.psd1)|*.psd1"
        $FileBrowser.Title = "Select a Configuration Profile to Validate Extensions"
        $Null = $FileBrowser.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost=$true}))
        $ConfigFile = $FileBrowser.FileName
    }
    if ([string]::IsNullOrEmpty($ConfigFile)) {
        $AvailableConfigs = Get-ChildItem -Path $ScriptRoot -Filter *.psd1
        if ($AvailableConfigs.Count -eq 0) { Write-Error "No .psd1 files found."; Exit }
        Write-Host "Available Profiles:"
        for ($i = 0; $i -lt $AvailableConfigs.Count; $i++) { Write-Host ("{0}) {1}" -f ($i + 1), $AvailableConfigs[$i].Name) }
        do { $Selection = Read-Host "`nChoose a number" } while ($Selection -notmatch '^\d+$' -or [int]$Selection -1 -lt 0 -or [int]$Selection -1 -ge $AvailableConfigs.Count)
        $ConfigFile = $AvailableConfigs[[int]$Selection - 1].FullName
    }
}

if (-not (Test-Path $ConfigFile)) { Write-Error "File not found."; Exit }

# 2. Ingest Data Tree
$Config = Import-PowerShellDataFile $ConfigFile
$Extensions = $Config.VSCodeExtensions

if (-not $Extensions) {
    Write-Warning "No 'VSCodeExtensions' array found inside $(Split-Path $ConfigFile -Leaf)."
    Exit
}

Write-Host "`n[+] Testing $($Extensions.Count) extensions against Marketplace API...`n"

# Marketplace API Configurations
$Uri = "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
$Headers = @{
    "Accept"       = "application/json;api-version=3.0-preview.1"
    "Content-Type" = "application/json"
}

$FailedExtensions = @()
$Count = 0

foreach ($Ext in $Extensions) {
    $Count++
    Write-Host ("[{0}/{1}] Querying: {2} " -f $Count, $Extensions.Count, $Ext.PadRight(45)) -NoNewline

    # Build criteria payload payload for standard marketplace lookups (filterType 7 = Exact Name matching)
    $Body = @{
        filters = @(
            @{
                criteria = @(
                    @{ filterType = 7; value = $Ext }
                )
            }
        )
        flags = 0x1
    } | ConvertTo-Json -Depth 4

    try {
        $Response = Invoke-RestMethod -Uri $Uri -Method Post -Headers $Headers -Body $Body -ErrorAction Stop
        
        # Dig into data mapping response to verify if metadata objects were returned
        $ResultsCount = $Response.results[0].extensions.Count
        
        if ($ResultsCount -gt 0) {
            Write-Host "[ PASS ]" -ForegroundColor Green
        } else {
            Write-Host "[ FAIL ]" -ForegroundColor Red
            $FailedExtensions += $Ext
        }
    } catch {
        Write-Host "[ ERROR ]" -ForegroundColor Yellow
        $FailedExtensions += "$Ext (API Error Connection)"
    }
}

Write-Host "`n=========================================" -ForegroundColor Cyan
if ($FailedExtensions.Count -eq 0) {
    Write-Host "[+] All extensions in this profile are valid and live on the marketplace." -ForegroundColor Green
} else {
    Write-Warning "[!] Target validation failed for $($FailedExtensions.Count) item(s):"
    foreach ($Fail in $FailedExtensions) {
        Write-Host "  -> $Fail" -ForegroundColor Yellow
    }
}