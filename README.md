# winconfig

A modular, zero-touch Windows post-flash script framework. It uses a core PowerShell engine (`setup.ps1`) to ingest configuration data profiles (`.psd1`), automating system tweaks, winget application deployment, shell environments, and profile layouts.

## Structure

```text
├── setup.ps1                   # Setup engine
├── configs
    ├── personal.psd1           # My goto personal configuration for windows
    ├── work.psd1               # My work configuration
├── tests
    ├── test-packages.ps1       # Package existance tester
    ├── test-vscextensions.psd1 # My work configuration
```

## How to Run

1. Open PowerShell as **Administrator**.
2. Run the following one-liner to clone the temporary instance and execute the engine:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; cd $env:TEMP; git clone https://github.com/rileywebb/winconfig.git; cd winconfig; .\setup.ps1
```

*Note: The script defaults to a native GUI file explorer prompt for profile selection, falling back to a clean CLI menu if running headlessly or over SSH.*

## Features

### 📦 Package & Module Provisioning

* **WinGet Core**: Automated concurrent installations for developer tools (LLVM, CMake, Ninja, GCC via WinLibs, Python 3.14), CLI tools (`eza`, `fzf`, `zoxide`), text editors (`Neovim`, `VSCode`), and system diagnostics.
* **PowerShell Modules**: Silently deploys `PSReadLine`, `Terminal-Icons`, and completion predictors without hitting untrusted repository prompts.
* **Automation Tasks**: Deploys a background scheduled task to safely update WinGet applications silently every Sunday at 3:00 AM.

### 🛠 System Architecture & Registry Tweaks

* **Performance Enhancements**: Unlocks NTFS long paths (removing the 260-character ceiling) and optimizes disk I/O for quick source compilation.
* **UI/UX Cleanup**: Forces modern system-wide dark mode, aligns taskbar icons left, restores the classic right-click context menus, and enables direct "End Task" functionality on taskbar applications.
* **Vim Ergonomics**: Modifies the native system layout registry to remap `Caps Lock` cleanly to `Escape`.
* **Telemetry and Bloat Removal**: Completely drops background Bing search integration in the Start Menu, kills telemetry nodes, and suppresses intrusive accessibility sticky key prompts.

### 💻 Environment Configuration

* **PowerToys Layouts**: Synchronizes application data configurations dynamically, copying over custom `FancyZones` boundaries and keyboard shortcuts before firing up the system runtime.
* **PowerShell Profile Customization**: Generates a zero-touch `$PROFILE` linking `OhMyPosh` styling, prediction view lists, custom key handlers, and recursive navigation wrappers natively on compilation launch.



## Customization

To modify tracking assets, adjust arrays directly within the `personal.psd1` file. The engine uses data boundaries dynamically, allowing you to scale multiple layout profiles side-by-side cleanly.