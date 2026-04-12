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
powershell -ExecutionPolicy Bypass -File E:\path\to\Onboarding\setup.ps1
```

> If WSL2 is not yet enabled, the script will enable it and ask you to **reboot**.
> After reboot, run the script again — it will continue from where it left off.

The script is fully **idempotent** — safe to re-run at any time. Already-installed items are skipped automatically.

### What gets installed

| Step | Key | What it does |
|---|---|---|
| 1 | `packages` | Installs apps via winget (VS Code, Git, Docker, Go, Node, Python, etc.) |
| 2 | `font` | Downloads and installs FiraCode Nerd Font |
| 3 | `nvim` | Copies your Neovim config to `%LOCALAPPDATA%\nvim` |
| 4 | `vscodevimrc` | Copies `.vscodevimrc` to your user profile |
| 5 | `vscode-settings` | Copies VS Code `settings.json` and `keybindings.json` |
| 6 | `vscode-extensions` | Installs all VS Code extensions |
| 7 | `wsl` | Installs WSL2 + Ubuntu |
| 7b | `zsh` | Sets up zsh + oh-my-zsh + nvm + Node + Python + Go inside WSL |
| 7c | `terminal` | Sets Windows Terminal default profile to Ubuntu |
| 8 | `ahk` | Installs mac-keymap.ahk and sets it to auto-start on login |

---

## Skipping steps

To skip one or more steps, edit the `$SKIP` array near the top of `setup.ps1`:

```powershell
# Skip WSL and zsh setup (e.g. already done, or not needed)
$SKIP = @("wsl", "zsh")

# Skip database apps and font
$SKIP = @("font")

# Skip everything except extensions
$SKIP = @("packages", "font", "nvim", "vscodevimrc", "vscode-settings", "wsl", "zsh", "terminal", "ahk")
```

Available skip keys: `packages`, `font`, `nvim`, `vscodevimrc`, `vscode-settings`, `vscode-extensions`, `wsl`, `zsh`, `terminal`, `ahk`

---

## Running install.sh manually inside WSL

If the zsh step failed or you want to re-run it separately, open Ubuntu and run:

```bash
# From the mounted Windows drive (adjust drive letter as needed)
sed -i 's/\r//' /mnt/e/github/setup-window/zsh/install.sh
bash /mnt/e/github/setup-window/zsh/install.sh
```

> The `sed` command strips Windows line endings — required if Git on Windows re-added them.

This installs inside WSL:
- zsh + oh-my-zsh (`robbyrussell` theme)
- `zsh-autosuggestions` plugin
- nvm + Node.js LTS
- Python 3 + pip + venv
- Go (latest stable)

Close and reopen the WSL terminal when done — zsh starts automatically.

---

## Mac Keyboard on Windows

The `mac-keymap.ahk` script is installed and auto-starts on login.
**Left Alt** acts as the `Cmd` key. **Win key** acts as `Option`.

| Mac shortcut | Windows (with AHK script) |
|---|---|
| `Cmd+C/V/X/Z/A/S` | `Alt+C/V/X/Z/A/S` |
| `Cmd+W/T/N/F/R/P` | `Alt+W/T/N/F/R/P` |
| `Cmd+Shift+Z` (redo) | `Alt+Shift+Z` |
| `Cmd+Tab` (app switch) | `Alt+Tab` |
| `Cmd+Q` (quit) | `Alt+Q` |
| `Cmd+Space` (Spotlight) | `Alt+Space` |
| `Cmd+Left/Right` (line start/end) | `Alt+Left/Right` |
| `Cmd+Up/Down` (top/bottom of file) | `Alt+Up/Down` |
| `Option+Left/Right` (word jump) | `Win+Left/Right` |
| `Option+Backspace` (delete word) | `Win+Backspace` |

To **pause/resume**: right-click the AHK icon in the system tray → Suspend.

> VS Code has its own keyboard handling — Alt key shortcuts for VS Code are defined directly in `vscode/keybindings.json` and work independently of AHK.

---

## VS Code Keybindings (Mac -> Windows)

| Mac | Windows |
|---|---|
| `Cmd+P` (quick open) | `Alt+P` |
| `Cmd+Shift+P` (command palette) | `Alt+Shift+P` |
| `Cmd+Shift+F` (global search) | `Alt+Shift+F` |
| `Cmd+B` (toggle sidebar) | `Alt+B` |
| `Alt+Cmd+H/L` (terminal pane focus) | `Ctrl+Alt+H/L` |
| `Ctrl+Cmd+K/J/H/L` (move editor) | `Ctrl+Alt+K/J/H/L` |
| `Alt+Cmd+Up/Down` (multi-cursor) | `Ctrl+Alt+Up/Down` |

---

## Line Endings Note

Shell scripts (`.sh`) must use LF line endings to run in WSL. If Git on Windows converts them to CRLF, run inside WSL before executing:

```bash
sed -i 's/\r//' path/to/script.sh
```

The `.gitattributes` in this repo enforces LF for `.sh` files automatically. To disable Git's auto-conversion globally on Windows:

```powershell
git config --global core.autocrlf false
```

---

## Updating configs later

If you change your Neovim or zsh config on the Mac, re-run `collect.sh` to refresh the package, then copy and re-run `setup.ps1` on Windows.
