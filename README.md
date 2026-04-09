# Mac to Windows Setup

Portable setup package to replicate a MacBook development environment on a Windows PC.

## Folder Structure

```
.
├── collect.sh          # Run on Mac to bundle latest configs
├── setup.ps1           # Run on Windows to install everything
├── mac-keymap.ahk      # AutoHotkey script — Mac-like keyboard on Windows
├── nvim/               # Neovim config (collected from ~/.config/nvim)
├── vscode/
│   ├── settings.json   # VS Code settings (Windows-adapted)
│   └── keybindings.json
└── zsh/
    ├── .zshrc          # WSL zsh config (oh-my-zsh + robbyrussell + autosuggestions)
    ├── .zshrc.mac      # Original Mac .zshrc (reference only)
    └── install.sh      # Runs inside WSL to set up zsh, nvm, Node, Python, Go
```

---

## Step 1 — On your Mac (pack your configs)

```bash
cd ~/Coding/Onboarding
bash collect.sh
```

Then zip the folder and copy it to the Windows PC (USB drive, cloud storage, etc.):

```bash
cd ~/Coding
zip -r Onboarding.zip Onboarding/
```

---

## Step 2 — On the Windows PC (run setup)

Open **PowerShell as Administrator** and run:

```powershell
powershell -ExecutionPolicy Bypass -File C:\path\to\Onboarding\setup.ps1
```

> If WSL2 is not yet enabled, the script will enable it and ask you to **reboot**.
> After reboot, run the script again — it will continue from where it left off.

### What gets installed automatically

| Category | Software |
|---|---|
| Editor | VS Code |
| Terminal | Windows Terminal |
| Shell | WSL2 + Ubuntu + zsh + oh-my-zsh |
| Neovim | Neovim + your full config |
| Git | Git for Windows |
| Docker | Docker Desktop |
| Database | DataGrip, MySQL, PostgreSQL |
| Languages | Go, Node.js LTS, Python 3 |
| Utilities | PowerToys, AutoHotkey |
| Font | FiraCode Nerd Font |

---

## Step 3 — Set up zsh inside WSL

After the main script finishes, open **Ubuntu** (from Start Menu or Windows Terminal) and run:

```bash
bash /tmp/mac-setup/zsh/install.sh
```

This installs inside WSL:
- zsh + oh-my-zsh
- `robbyrussell` theme
- `zsh-autosuggestions` plugin
- nvm + Node.js LTS
- Python 3 + pip + venv
- Go (latest stable)

Close and reopen the WSL terminal when done — zsh starts automatically.

---

## Mac Keyboard on Windows

The `mac-keymap.ahk` script is installed and auto-starts on login.
**Left Alt** acts as the `Cmd` key. **Win key** acts as `Option`.

| Mac shortcut | Windows (with script) |
|---|---|
| `Cmd+C/V/X/Z/A/S` | `Alt+C/V/X/Z/A/S` |
| `Cmd+W/T/N/F/R` | `Alt+W/T/N/F/R` |
| `Cmd+Tab` | `Alt+Tab` |
| `Cmd+Q` (quit) | `Alt+Q` |
| `Cmd+Space` (Spotlight) | `Alt+Space` |
| `Cmd+Left/Right` (line start/end) | `Alt+Left/Right` |
| `Cmd+Up/Down` (top/bottom of file) | `Alt+Up/Down` |
| `Cmd+Shift+Z` (redo) | `Alt+Shift+Z` |
| `Option+Left/Right` (word jump) | `Win+Left/Right` |
| `Option+Backspace` (delete word) | `Win+Backspace` |

To **pause/resume**: right-click the green `H` icon in the system tray → Suspend.

---

## VS Code Keybinding Changes (Mac → Windows)

| Mac | Windows |
|---|---|
| `Cmd+*` | `Ctrl+*` (VS Code handles this natively) |
| `Alt+Cmd+H/L` | `Ctrl+Alt+H/L` (terminal pane focus) |
| `Ctrl+Cmd+K/J/H/L` | `Ctrl+Alt+K/J/H/L` (move editor between groups) |
| `Alt+Cmd+K/J` | `Ctrl+Alt+Up/Down` (multi-cursor) |

---

## Updating configs later

If you change your Neovim or zsh config on the Mac, re-run `collect.sh` to refresh the package, then copy and re-run `setup.ps1` on Windows.
