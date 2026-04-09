# Windows Setup Script
# Run as Administrator in PowerShell:
#   powershell -ExecutionPolicy Bypass -File setup.ps1

$ErrorActionPreference = "Stop"
$SETUP_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

function Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "[ OK ] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }

function Test-WinInstalled($displayName) {
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($path in $regPaths) {
        $found = Get-ItemProperty $path -ErrorAction SilentlyContinue |
                 Where-Object { $_.DisplayName -like "*$displayName*" }
        if ($found) { return $true }
    }
    return $false
}

# ─── 1. Install software via winget ────────────────────────────────────────────
Info "Installing packages via winget..."

$packages = @(
    @{ id = "Microsoft.VisualStudioCode";   name = "VS Code";          check = "Visual Studio Code" },
    @{ id = "Neovim.Neovim";               name = "Neovim";           check = "Neovim" },
    @{ id = "Git.Git";                      name = "Git";              check = "Git" },
    @{ id = "Microsoft.PowerToys";          name = "PowerToys";        check = "PowerToys" },
    @{ id = "Microsoft.WindowsTerminal";    name = "Windows Terminal"; check = "Windows Terminal" },
    @{ id = "AutoHotkey.AutoHotkey";        name = "AutoHotkey";       check = "AutoHotkey" },
    @{ id = "Docker.DockerDesktop";         name = "Docker Desktop";   check = "Docker Desktop" },
    @{ id = "JetBrains.DataGrip";          name = "DataGrip";         check = "DataGrip" },
    @{ id = "Oracle.MySQL";                name = "MySQL";            check = "MySQL" },
    @{ id = "PostgreSQL.PostgreSQL";        name = "PostgreSQL";       check = "PostgreSQL" },
    @{ id = "GoLang.Go";                   name = "Go";               check = "Go Programming Language" },
    @{ id = "OpenJS.NodeJS.LTS";           name = "Node.js LTS";      check = "Node.js" },
    @{ id = "Python.Python.3";             name = "Python 3";         check = "Python" }
)

foreach ($pkg in $packages) {
    Info "Checking $($pkg.name)..."
    if (Test-WinInstalled $pkg.check) {
        Ok "$($pkg.name) already installed"
    } else {
        Info "Installing $($pkg.name)..."
        winget install --id $pkg.id -e --silent --accept-package-agreements --accept-source-agreements
        Ok "$($pkg.name) installed"
    }
}

# ─── 2. Install FiraCode Nerd Font ─────────────────────────────────────────────
Info "Installing FiraCode Nerd Font..."
$fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
$fontZip = "$env:TEMP\FiraCode.zip"
$fontDir = "$env:TEMP\FiraCode"

if (-not (Test-Path "$env:SystemRoot\Fonts\FiraCode*.ttf")) {
    Invoke-WebRequest -Uri $fontUrl -OutFile $fontZip
    Expand-Archive -Path $fontZip -DestinationPath $fontDir -Force
    $fonts = Get-ChildItem "$fontDir\*.ttf"
    $fontDest = "$env:SystemRoot\Fonts"
    foreach ($font in $fonts) {
        Copy-Item $font.FullName $fontDest -Force
        $regName = $font.BaseName
        Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -Name "$regName (TrueType)" -Value $font.Name -Type String
    }
    Ok "FiraCode Nerd Font installed"
} else {
    Ok "FiraCode Nerd Font already installed"
}

# ─── 3. Copy Neovim config ─────────────────────────────────────────────────────
Info "Copying Neovim config..."
$nvimDest = "$env:LOCALAPPDATA\nvim"
$nvimSrc  = Join-Path $SETUP_DIR "nvim"

if (Test-Path $nvimSrc) {
    if (Test-Path $nvimDest) {
        Warn "Existing nvim config found at $nvimDest -- backing up to ${nvimDest}.bak"
        if (Test-Path "${nvimDest}.bak") { Remove-Item "${nvimDest}.bak" -Recurse -Force }
        Rename-Item $nvimDest "${nvimDest}.bak"
    }
    Copy-Item -Recurse $nvimSrc $nvimDest
    Ok "Neovim config copied to $nvimDest"
} else {
    Warn "nvim/ folder not found in setup dir -- run collect.sh on your Mac first"
}

# ─── 4. Copy .vscodevimrc ──────────────────────────────────────────────────────
Info "Copying .vscodevimrc..."
$vimrcSrc = Join-Path $SETUP_DIR ".vscodevimrc"
if (Test-Path $vimrcSrc) {
    Copy-Item $vimrcSrc "$env:USERPROFILE\.vscodevimrc" -Force
    Ok ".vscodevimrc copied to $env:USERPROFILE"
} else {
    Warn ".vscodevimrc not found in setup dir"
}

# ─── 5. Copy VS Code settings ──────────────────────────────────────────────────
Info "Copying VS Code settings..."
$vscodeDest = "$env:APPDATA\Code\User"

if (-not (Test-Path $vscodeDest)) {
    New-Item -ItemType Directory -Path $vscodeDest | Out-Null
}

$settingsSrc    = Join-Path $SETUP_DIR "vscode\settings.json"
$keybindingsSrc = Join-Path $SETUP_DIR "vscode\keybindings.json"

if (Test-Path $settingsSrc) {
    Copy-Item $settingsSrc "$vscodeDest\settings.json" -Force
    Ok "VS Code settings.json copied"
} else {
    Warn "vscode/settings.json not found"
}

if (Test-Path $keybindingsSrc) {
    Copy-Item $keybindingsSrc "$vscodeDest\keybindings.json" -Force
    Ok "VS Code keybindings.json copied"
} else {
    Warn "vscode/keybindings.json not found"
}

# ─── 6. Install VS Code extensions ─────────────────────────────────────────────
Info "Installing VS Code extensions..."

$codeCli = @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
    "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $codeCli) {
    Warn "VS Code CLI not found -- skipping extensions. Open VS Code once then re-run."
} else {

$extensions = @(
    "42crunch.vscode-openapi",
    "aaron-bond.better-comments",
    "adrianwilczynski.add-reference",
    "adrianwilczynski.asp-net-core-switcher",
    "adrianwilczynski.blazor-snippet-pack",
    "adrianwilczynski.csharp-to-typescript",
    "adrianwilczynski.libman",
    "adrianwilczynski.namespace",
    "adrianwilczynski.terminal-commands",
    "adrianwilczynski.toggle-hidden",
    "adrianwilczynski.user-secrets",
    "ahmadalli.vscode-nginx-conf",
    "amiralizadeh9480.laravel-extra-intellisense",
    "anderseandersen.html-class-suggestions",
    "antfu.goto-alias",
    "anthropic.claude-code",
    "atomiks.moonlight",
    "bierner.markdown-mermaid",
    "bmewburn.vscode-intelephense-client",
    "bpruitt-goddard.mermaid-markdown-syntax-highlighting",
    "bradlc.vscode-tailwindcss",
    "chakrounanas.turbo-console-log",
    "christian-kohler.path-intellisense",
    "codezombiech.gitignore",
    "codingyu.laravel-goto-view",
    "dariofuzinato.vue-peek",
    "davidanson.vscode-markdownlint",
    "dbaeumer.vscode-eslint",
    "digitalbrainstem.javascript-ejs-support",
    "docker.docker",
    "doggy8088.netcore-editorconfiggenerator",
    "doggy8088.netcore-extension-pack",
    "doggy8088.netcore-snippets",
    "doggy8088.quicktype-refresh",
    "donjayamanne.githistory",
    "drblury.protobuf-vsc",
    "dsznajder.es7-react-js-snippets",
    "eamodio.gitlens",
    "editorconfig.editorconfig",
    "esbenp.prettier-vscode",
    "eserozvataf.one-dark-pro-monokai-darker",
    "formulahendry.auto-close-tag",
    "formulahendry.auto-rename-tag",
    "formulahendry.code-runner",
    "formulahendry.dotnet",
    "formulahendry.dotnet-test-explorer",
    "foxundermoon.shell-format",
    "franzgollhammer.jb-fleet-dark",
    "frhtylcn.pythonsnippets",
    "github.copilot-chat",
    "github.github-vscode-theme",
    "github.vscode-pull-request-github",
    "glenn2223.live-sass",
    "glitchbl.laravel-create-view",
    "golang.go",
    "grapecity.gc-excelviewer",
    "ihunte.laravel-blade-wrapper",
    "james-yu.latex-workshop",
    "jebbs.plantuml",
    "jeremyrajan.webpack",
    "jmrog.vscode-nuget-package-manager",
    "jripouteau.adonis-vscode-extension",
    "k--kato.docomment",
    "kreativ-software.csharpextensions",
    "lewisyliu.ef-core-snippets",
    "mads-hartmann.bash-ide-vscode",
    "mhutchie.git-graph",
    "mikestead.dotenv",
    "mongodb.mongodb-vscode",
    "mrmlnc.vscode-scss",
    "ms-azuretools.vscode-containers",
    "ms-azuretools.vscode-docker",
    "ms-dotnettools.csdevkit",
    "ms-dotnettools.csharp",
    "ms-dotnettools.vscode-dotnet-runtime",
    "ms-kubernetes-tools.vscode-kubernetes-tools",
    "ms-python.black-formatter",
    "ms-python.debugpy",
    "ms-python.isort",
    "ms-python.python",
    "ms-python.vscode-pylance",
    "ms-python.vscode-python-envs",
    "ms-vscode-remote.remote-containers",
    "ms-vscode-remote.remote-ssh",
    "ms-vscode-remote.remote-ssh-edit",
    "ms-vscode-remote.remote-wsl",
    "ms-vscode.live-server",
    "ms-vscode.makefile-tools",
    "ms-vscode.remote-explorer",
    "naoray.laravel-goto-components",
    "natizyskunk.sftp",
    "naumovs.color-highlight",
    "neonxp.gotools",
    "nuxtr.nuxt-vscode-extentions",
    "nuxtr.nuxtr-vscode",
    "octref.vetur",
    "onecentlin.laravel-blade",
    "onecentlin.laravel-extension-pack",
    "onecentlin.laravel5-snippets",
    "orta.vscode-jest",
    "pascalreitermann93.vscode-yaml-sort",
    "patbenatar.advanced-new-file",
    "patcx.vscode-nuget-gallery",
    "pflannery.vscode-versionlens",
    "pgl.laravel-jump-controller",
    "piotrpalarz.vscode-gitignore-generator",
    "pkief.material-icon-theme",
    "pomdtr.excalidraw-editor",
    "qhoekman.language-plantuml",
    "qvist.jetbrains-new-ui-dark-theme",
    "rangav.vscode-thunder-client",
    "redhat.fabric8-analytics",
    "redhat.vscode-community-server-connector",
    "redhat.vscode-rsp-ui",
    "redhat.vscode-xml",
    "redhat.vscode-yaml",
    "rexshi.phpdoc-comment-vscode-plugin",
    "riazxrazor.html-to-jsx",
    "ritwickdey.liveserver",
    "romanrei.material-dark",
    "ryannaddy.laravel-artisan",
    "shd101wyy.markdown-preview-enhanced",
    "shufo.vscode-blade-formatter",
    "sibiraj-s.vscode-scss-formatter",
    "skyran.js-jsx-snippets",
    "sleistner.vscode-fileutils",
    "souche.vscode-mindmap",
    "standard.vscode-standard",
    "streetsidesoftware.code-spell-checker",
    "sumneko.lua",
    "taodnongwu.ejs-snippets",
    "thekalinga.bootstrap4-vscode",
    "tintoy.msbuild-project-tools",
    "vivaxy.vscode-conventional-commits",
    "vscode-icons-team.vscode-icons",
    "vscodevim.vim",
    "vue.volar",
    "wart.ariake-dark",
    "wayou.vscode-todo-highlight",
    "william-voyek.vscode-nginx",
    "wscats.eno",
    "xabikos.javascriptsnippets",
    "xdebug.php-debug",
    "yzhang.markdown-all-in-one",
    "zainchen.json",
    "zenghongtu.vscode-asciiflow2",
    "zhuangtongfa.material-theme"
)

    foreach ($ext in $extensions) {
        & $codeCli --install-extension $ext --force 2>$null
        Ok "Extension: $ext"
    }
}

# ─── 7. WSL2 + Ubuntu + zsh ───────────────────────────────────────────────────
Info "Setting up WSL2 and Ubuntu..."

$wslWorking = $false
try {
    wsl --status 2>$null | Out-Null
    $wslWorking = ($LASTEXITCODE -eq 0)
} catch { }

if (-not $wslWorking) {
    Info "Installing WSL2..."
    wsl --install --no-distribution
    Warn "WSL2 installed. A REBOOT is required before continuing."
    Warn "After reboot, re-run this script to continue setup."
    exit 0
} else {
    Ok "WSL2 already installed"
}

$ubuntuInstalled = wsl --list --quiet 2>$null | Select-String "Ubuntu"
if (-not $ubuntuInstalled) {
    Info "Installing Ubuntu..."
    winget install --id Canonical.Ubuntu.2404 --silent --accept-package-agreements --accept-source-agreements
    Ok "Ubuntu installed"
} else {
    Ok "Ubuntu already installed"
}

# Copy zsh setup into WSL home and run it
Info "Running zsh/oh-my-zsh setup inside WSL..."
$zshSrc = Join-Path $SETUP_DIR "zsh"
if (-not (Test-Path $zshSrc)) {
    Warn "zsh/ folder not found in setup dir -- skipping zsh setup"
} else {
    $wslZshSrc = $zshSrc -replace '\\', '/' -replace '^([A-Za-z]):', '/mnt/$1'.ToLower()
    wsl -d Ubuntu -e bash -c "mkdir -p /tmp/mac-setup/zsh && cp -r '$wslZshSrc/.' /tmp/mac-setup/zsh/ && bash /tmp/mac-setup/zsh/install.sh"
    Ok "zsh setup complete inside WSL"
}

# ─── 8. Mac keymap (AutoHotkey) ───────────────────────────────────────────────
Info "Setting up Mac-like keymap..."
$ahkSrc = Join-Path $SETUP_DIR "mac-keymap.ahk"
$ahkDest = "$env:USERPROFILE\mac-keymap.ahk"
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"

if (Test-Path $ahkSrc) {
    Copy-Item $ahkSrc $ahkDest -Force
    # Create a shortcut in Startup folder so it runs on login
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut("$startupFolder\mac-keymap.lnk")
    $shortcut.TargetPath = $ahkDest
    $shortcut.Save()
    # Run it now
    Start-Process $ahkDest
    Ok "mac-keymap.ahk installed and running (auto-starts on login)"
} else {
    Warn "mac-keymap.ahk not found in setup dir"
}

# ─── 8. PowerToys reminder ─────────────────────────────────────────────────────
Write-Host ""
Write-Host ""
Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Magenta
Write-Host " Mac Keymap is active! Left Alt now works like Cmd key." -ForegroundColor Magenta
Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Magenta
Write-Host " Key layout:" -ForegroundColor White
Write-Host "   Left Alt  = Cmd  (copy, paste, save, undo, tabs...)" -ForegroundColor White
Write-Host "   Win key   = Option (word-jump with Win+Left/Right)" -ForegroundColor White
Write-Host "   Left Ctrl = Ctrl (unchanged)" -ForegroundColor White
Write-Host ""
Write-Host " Quick reference:" -ForegroundColor Yellow
Write-Host "   Alt+C/V/X/Z/A/S/W/T/N/F  = same as Mac Cmd+..." -ForegroundColor White
Write-Host "   Alt+Left/Right            = Home / End (line)" -ForegroundColor White
Write-Host "   Alt+Up/Down               = Top / Bottom of file" -ForegroundColor White
Write-Host "   Alt+Q                     = Quit app (Alt+F4)" -ForegroundColor White
Write-Host "   Alt+Tab                   = App switcher" -ForegroundColor White
Write-Host "   Alt+Space                 = Windows Search (Spotlight)" -ForegroundColor White
Write-Host "   Win+Left/Right            = Jump word (Option+Arrow)" -ForegroundColor White
Write-Host "   Win+Backspace             = Delete word" -ForegroundColor White
Write-Host ""
Write-Host " To pause/resume keymap: right-click AHK icon in tray" -ForegroundColor Cyan
Write-Host ""
Write-Host "All done! Restart VS Code to apply changes." -ForegroundColor Green
