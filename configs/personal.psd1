@{
    ProfileName = "Personal Desktop"
    WingetApps  = @(
        # --- Core Dev, Version Control & API Tools ---
        "Git.Git",
        "GitHub.cli",
        "JesseDuffield.lazygit",
        "Bruno.Bruno",

        # --- IDEs, Text Editors & AI Assistance ---
        "Microsoft.VisualStudioCode",
        "Neovim.Neovim",
        "Notepad++.Notepad++",
        "Anthropic.ClaudeCode",

        # --- Toolchains, Build Systems & Runtimes ---
        "Kitware.CMake",
        "Ninja-build.Ninja",
        "LLVM.LLVM",
        "OpenJS.NodeJS",
        "Python.Python.3.14",
        "BrechtSanders.WinLibs.POSIX.UCRT",
        "Ccache.Ccache",
        # "NSA.Ghidra",
        "x64dbg.x64dbg",
        "MHNexus.HxD",
        "Rufus.Rufus",
        "DBBrowserForSQLite.DBBrowserForSQLite",
        
        # --- Terminal Environment & Modern CLI Utilities ---
        "Microsoft.WindowsTerminal",
        "JanDeDobbeleer.OhMyPosh",
        "DEVCOM.JetBrainsMonoNerdFont",
        "Fastfetch-cli.Fastfetch",
        "eza-community.eza",
        "junegunn.fzf",
        "sharkdp.fd",
        "ajeetdsouza.zoxide",
        "BurntSushi.ripgrep.MSVC",
        "Amazon.AWSCLI",
        "Microsoft.AzureCLI",
        "cURL.cURL",

        # --- Containers & Networking ---
        "Docker.DockerDesktop",
        "WinSCP.WinSCP",
        "Insecure.Nmap",

        # --- Advanced System Internals & Security Diagnostics ---
        "Microsoft.Sysinternals.Suite",
        "WinsiderSS.SystemInformer",
        "WerWolv.ImHex",
        "GnuPG.Gpg4win",

        # --- System Utilities, Desktop Env & Package Management ---
        "Microsoft.PowerToys",
        "Devolutions.UniGetUI",
        "voidtools.Everything",
        "WinDirStat.WinDirStat",
        "ozone10.7zip.Dark",
        "CharlesMilette.TranslucentTB",
        "Bitwarden.Bitwarden",
        "FilesCommunity.Files",
        "Proton.ProtonVPN",

        # --- Web Browsers ---
        "Mozilla.Firefox.DeveloperEdition",
        "Google.Chrome.Dev",

        # --- Creative Layout, 3D & Document Processing ---
        "BlenderFoundation.Blender",
        "dotPDN.PaintDotNet",
        "Inkscape.Inkscape",
        "MiKTeX.MiKTeX",

        # --- Social, Media & Gaming ---
        "Valve.Steam",
        "Discord.Discord",
        "Spicetify.Spicetify",
        "Spotify.Spotify",
        "VideoLAN.VLC",
        "mpv-player.mpv-CI.MSVC"
    )

    Features    = @(
        "VirtualMachinePlatform", 
        "Microsoft-Windows-Subsystem-Linux",
        "Containers-DisposableClientVM"
    )

    Tweaks      = @{
        # UI & Explorer Layout
        ShowHiddenFiles                 = $true
        TaskbarAlignLeft                = $true
        EnableDarkMode                  = $true
        ExplorerOpenToThisPC            = $true
        # ClassicContextMenu              = $true
        EnableCommandPromptContextMenu  = $true
        InstantMenus                    = $true
        TaskbarEndTask                  = $true
        
        # Privacy & Context Cleanups
        DisableBingSearch               = $true
        DisableRecentFiles              = $true
        DisableWidgets                  = $true
        DisableAdvertisingID            = $true
        DisableTailoredExperiences      = $true
        DisableSuggestedContent         = $true
        
        # Developer Performance & Quality of Life
        EnableDeveloperMode             = $true
        EnableLongPaths                 = $true
        DisableStickyKeys               = $true
        PreventSleepOnPower             = $true
        EnableVerboseLogon              = $true
    }

    Commands   = @(
        "Install-Module PSReadLine -Scope CurrentUser",
        "Install-Module Terminal-Icons -Scope CurrentUser",
        "Install-Module z -Scope CurrentUser",
        "Install-Module PSFzf -Scope CurrentUser",
        "Install-Module CompletionPredictor -Scope CurrentUser"
    )

    VSCodeExtensions = @(
        "ms-vscode.cpptools",                  # C/C++ IntelliSense & Debugging
        "ms-vscode.cpp-devtools",              # CMake/C++ Build tools
        "ms-toolsai.jupyter",                  # Jupyter Notebook support
        "ms-toolsai.jupyter-keymap",           # Jupyter keybindings
        "twxs.cmake",                          # CMake language support
        "ms-python.python",                    # Python language support
        "sumneko.lua",                         # Lua development
        "catppuccin.catppuccin-vsc",
        "emmanuelbeziat.vscode-great-icons",
        "xaver.clang-format"
    )
}