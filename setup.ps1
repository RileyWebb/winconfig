<#
.SYNOPSIS
    Windows Post-Flash Automation Script (Dynamic Config Selector)
#>

# 1. Ensure Admin Privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as Administrator. Relaunching..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Add-Type -AssemblyName System.Windows.Forms

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   DYNAMIC WINDOWS POST-FLASH ENGINE     " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 2. Select Configuration File (GUI File Picker with CLI fallback)
$ConfigFile = $null

# Check if we are running in a GUI session
if ([Environment]::UserInteractive) {
    Write-Host "[*] Opening file explorer to select profile..." -ForegroundColor Yellow
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
    $FileBrowser.InitialDirectory = $ScriptRoot
    $FileBrowser.Filter = "PowerShell Data Files (*.psd1)|*.psd1"
    $FileBrowser.Title = "Select your Post-Flash Configuration Profile"
    
    # ShowDialog requires a window wrapper sometimes to force focus to front
    $Null = $FileBrowser.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))
    $ConfigFile = $FileBrowser.FileName
}

# Fallback to CLI list if GUI dialog was cancelled or isn't available
if ([string]::IsNullOrEmpty($ConfigFile)) {
    Write-Host "[!] No file chosen via GUI. Scanning script directory..." -ForegroundColor Yellow
    $AvailableConfigs = Get-ChildItem -Path $ScriptRoot -Filter *.psd1
    
    if ($AvailableConfigs.Count -eq 0) {
        Write-Error "No .psd1 configuration files found in $ScriptRoot"
        Exit
    }

    Write-Host "`nAvailable Profiles:"
    for ($i = 0; $i -lt $AvailableConfigs.Count; $i++) {
        Write-Host ("{0}) {1}" -f ($i + 1), $AvailableConfigs[$i].Name)
    }

    do {
        $Selection = Read-Host "`nChoose a profile configuration number"
        $Index = [int]$Selection - 1
    } while ($Selection -notmatch '^\d+$' -or $Index -lt 0 -or $Index -ge $AvailableConfigs.Count)

    $ConfigFile = $AvailableConfigs[$Index].FullName
}

# 3. Load & Validate Selected Config
Write-Host "`n[+] Loading: $ConfigFile" -ForegroundColor Green
$Config = Import-PowerShellDataFile $ConfigFile

$ProfileLabel = if ($Config.ProfileName) { $Config.ProfileName } else { Split-Path $ConfigFile -Leaf }
Write-Host "Running configuration for: $ProfileLabel" -ForegroundColor Cyan
Write-Host "-----------------------------------------"

# 4. Enable Windows Optional Features
if ($Config.Features) {
    Write-Host "`n[*] Enabling Windows Features..." -ForegroundColor Yellow
    foreach ($Feature in $Config.Features) {
        Write-Host " -> Enabling $Feature"
        Enable-WindowsOptionalFeature -Online -FeatureName $Feature -All -NoRestart | Out-Null
    }
}

# 5. Run Custom PowerShell Commands (Modules & Initializers)
if ($Config.Commands) {
    Write-Host "`n[*] Executing Profile PowerShell Commands..." -ForegroundColor Yellow
    
    # Suppress installation prompts by setting PSGallery to Trusted explicitly
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction SilentlyContinue
    
    foreach ($Cmd in $Config.Commands) {
        Write-Host " -> Executing: $Cmd" -ForegroundColor White
        Invoke-Expression $Cmd | Out-Null
    }
}

# 6. Install Applications via WinGet
if ($Config.WingetApps) {
    Write-Host "`n[*] Installing Applications via WinGet..." -ForegroundColor Yellow
    $env:Path += ";$env:LocalAppData\Microsoft\WindowsApps"
    
    foreach ($App in $Config.WingetApps) {
        Write-Host " -> Installing $App..." -ForegroundColor White
        winget install --id $App --silent --accept-source-agreements --accept-package-agreements | Out-Null
    }
}

# 7. Apply Registry Tweaks
if ($Config.Tweaks) {
    Write-Host "`n[*] Applying System Registry Tweaks..." -ForegroundColor Yellow
    $Tweaks = $Config.Tweaks

    if ($Tweaks.ShowHiddenFiles) {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
    }

    if ($Tweaks.TaskbarAlignLeft) {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0 -ErrorAction SilentlyContinue
    }

    if ($Tweaks.DisableTelemetry) {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -ErrorAction SilentlyContinue
    }
    
    if ($Tweaks.EnableDarkMode) {
        Write-Host " -> Enabling Dark Mode..." -ForegroundColor White
        $ThemePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        if (-not (Test-Path $ThemePath)) { New-Item -Path $ThemePath -Force | Out-Null }
        Set-ItemProperty -Path $ThemePath -Name "AppsUseLightTheme" -Value 0
        Set-ItemProperty -Path $ThemePath -Name "SystemUsesLightTheme" -Value 0
    }

    if ($Tweaks.DisableBingSearch) {
        Write-Host " -> Disabling Bing in Start Menu..." -ForegroundColor White
        $PolicyExplorerPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
        
        if (-not (Test-Path $PolicyExplorerPath)) { 
            New-Item -Path $PolicyExplorerPath -Force | Out-Null 
        }
        
        # Disables web search results in the Start Menu completely
        Set-ItemProperty -Path $PolicyExplorerPath -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord
    }

    if ($Tweaks.EnableDeveloperMode) {
        Write-Host " -> Enabling Developer Mode..." -ForegroundColor White

        $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
        if (!(Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }

        Set-ItemProperty $Path AllowDevelopmentWithoutDevLicense -Type DWord -Value 1
        Set-ItemProperty $Path AllowAllTrustedApps -Type DWord -Value 1
    }

    # Open Explorer to This PC
    if ($Tweaks.ExplorerOpenToThisPC) {
        Write-Host " -> Explorer opens to This PC"
        Set-ItemProperty `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            LaunchTo 1
    }

    # Disable Recent Files
    if ($Tweaks.DisableRecentFiles) {
        Write-Host " -> Disabling Recent Files"
        Set-ItemProperty `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" `
            ShowRecent 0
    }

    # Disable Widgets
    if ($Tweaks.DisableWidgets) {
        Write-Host " -> Disabling Widgets..." -ForegroundColor White
        $AdvancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $AdvancedPath -Name "TaskbarDa" -Value 0 -Force -ErrorAction SilentlyContinue
    }

    # Restore Classic Context Menu
    if ($Tweaks.ClassicContextMenu) {
        Write-Host " -> Restoring classic context menu"

        $ClassicPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"

        New-Item -Path $ClassicPath -Force | Out-Null
        Set-ItemProperty $ClassicPath -Name "(Default)" -Value ""
    }

    # Restore "Open Command Window Here"
    if ($Tweaks.EnableCommandPromptContextMenu) {
        Write-Host " -> Restoring Command Prompt context menu"

        Remove-ItemProperty `
            -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\cmd" `
            -Name "HideBasedOnVelocityId" `
            -ErrorAction SilentlyContinue
    }

    # Faster menu animations
    if ($Tweaks.InstantMenus) {
        Write-Host " -> Setting menu delay to 0"

        Set-ItemProperty `
            "HKCU:\Control Panel\Desktop" `
            MenuShowDelay "0"
    }

    # Disable Advertising ID
    if ($Tweaks.DisableAdvertisingID) {
        Write-Host " -> Disabling Advertising ID"

        Set-ItemProperty `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" `
            Enabled 0
    }

    # Disable Tailored Experiences
    if ($Tweaks.DisableTailoredExperiences) {
        Write-Host " -> Disabling Tailored Experiences"

        Set-ItemProperty `
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" `
            TailoredExperiencesWithDiagnosticDataEnabled 0
    }

    # Disable Suggested Content
    if ($Tweaks.DisableSuggestedContent) {

        Write-Host " -> Disabling Suggested Content"

        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"

        @(
            "SubscribedContent-338388Enabled",
            "SubscribedContent-338389Enabled",
            "SubscribedContent-353694Enabled",
            "SubscribedContent-353696Enabled"
        ) | ForEach-Object {
            Set-ItemProperty $Path $_ 0
        }
    }

    # Removes the ancient 260-character path limit—critical for deep C++ build trees or node_modules.
    if ($Tweaks.EnableLongPaths) {
        Write-Host " -> Enabling NTFS Long Paths..." -ForegroundColor White
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -Force | Out-Null
    }

    # Allows you to kill frozen binaries instantly from the taskbar without opening Task Manager/System Informer.
    if ($Tweaks.TaskbarEndTask) {
        Write-Host " -> Enabling Taskbar 'End Task' option..." -ForegroundColor White
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Name "TaskbarEndTask" -Value 1 -Force | Out-Null
    }

    # Prevents the intrusive accessibility dialog box when smashing the Shift key during compilation shortcuts or gaming.
    if ($Tweaks.DisableStickyKeys) {
        Write-Host " -> Muting Sticky Keys popups..." -ForegroundColor White
        Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "506" -Force | Out-Null
        Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\ToggleKeys" -Name "Flags" -Value "58" -Force | Out-Null
    }

    # Ensures your computer won't drop into low-power sleep state in the middle of a long build or download.
    if ($Tweaks.PreventSleepOnPower) {
        Write-Host " -> Optimizing power timeout for AC power..." -ForegroundColor White
        powercfg /change standby-timeout-ac 0
        powercfg /change monitor-timeout-ac 15
    }
    
    # Displays detailed status messages during boot, logon, logoff, and shutdown
    if ($Tweaks.EnableVerboseLogon) {
        Write-Host " -> Enabling Verbose Logon Status Messages..." -ForegroundColor White
        $SystemPolicyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        
        if (-not (Test-Path $SystemPolicyPath)) { 
            New-Item -Path $SystemPolicyPath -Force | Out-Null 
        }
        
        Set-ItemProperty -Path $SystemPolicyPath -Name "VerboseStatus" -Value 1 -Type DWord -Force | Out-Null
    }

    # Restart Explorer to apply UI tweaks immediately
    Stop-Process -Name explorer -Force
}

# 8. Install Visual Studio Code Extensions
if ($Config.VSCodeExtensions) {
    Write-Host "`n[*] Deploying VSCode Extensions..." -ForegroundColor Yellow
    
    # Force refresh env path to discover the fresh WinGet VSCode installation path
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # Locate code binary or fall back to standard local paths if environment registry hasn't broadcasted
    $CodeBin = Get-Command "code" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if (-not $CodeBin) {
        $UserPath   = "$env:LocalAppData\Programs\Microsoft VS Code\bin\code.cmd"
        $SystemPath = "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
        if (Test-Path $UserPath) { $CodeBin = $UserPath }
        elseif (Test-Path $SystemPath) { $CodeBin = $SystemPath }
    }

    if ($CodeBin) {
        foreach ($Extension in $Config.VSCodeExtensions) {
            Write-Host " -> Initializing: $Extension" -ForegroundColor White
            # Run the installer command natively via invocation operator
            & $CodeBin --install-extension $Extension --force | Out-Null
        }
    } else {
        Write-Warning "VSCode CLI installation endpoint ('code') not found. Skipping array targets."
    }
}

Write-Host "`n[+] Configuration Complete for $ProfileLabel!" -ForegroundColor Green