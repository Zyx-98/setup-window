#!/bin/bash
# Ubuntu Setup Script
# Run on a fresh Ubuntu 22.04 / 24.04 desktop:
#   bash setup-ubuntu.sh
#
# To skip specific steps, edit the SKIP array below.
# Available skip keys:
#   packages          - apt package installs
#   font              - FiraCode Nerd Font
#   nvim              - Neovim config copy
#   vscodevimrc       - .vscodevimrc copy
#   vscode-settings   - VS Code settings + keybindings
#   vscode-extensions - VS Code extension installs
#   zsh               - zsh/oh-my-zsh + nvm + Node + Python + Go setup
#   keymap            - Mac-like keyboard via keyd
#   screenshot        - Flameshot + shortcut binding
#
# Example — skip databases and keymap:
#   SKIP="databases keymap" bash setup-ubuntu.sh

SKIP="${SKIP:-}"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ok()   { echo -e "\033[32m[ OK ]\033[0m $1"; }
info() { echo -e "\033[36m[INFO]\033[0m $1"; }
warn() { echo -e "\033[33m[WARN]\033[0m $1"; }
skip() { echo -e "\033[90m[SKIP]\033[0m $1"; }

should_skip() { echo "$SKIP" | grep -qw "$1"; }

# ─── 1. Install packages ───────────────────────────────────────────────────────
if should_skip "packages"; then skip "packages -- skipped"; else

info "Updating apt..."
sudo apt-get update -qq

info "Installing base packages..."
sudo apt-get install -y \
    git curl wget unzip build-essential \
    zsh ca-certificates gnupg lsb-release \
    python3 python3-pip python3-venv \
    ripgrep fd-find fzf xclip xsel

# VS Code (Microsoft apt repo)
if ! command -v code &>/dev/null; then
    info "Installing VS Code..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | \
        sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" | \
        sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y code
    ok "VS Code installed"
else
    ok "VS Code already installed"
fi

# Neovim (AppImage — always latest stable, avoids outdated apt version)
if ! command -v nvim &>/dev/null; then
    info "Installing Neovim..."
    NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"
    sudo wget -q "$NVIM_URL" -O /usr/local/bin/nvim
    sudo chmod +x /usr/local/bin/nvim
    ok "Neovim installed"
else
    ok "Neovim already installed: $(nvim --version | head -1)"
fi

# Docker
if ! command -v docker &>/dev/null; then
    info "Installing Docker..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker "$USER"
    ok "Docker installed (log out and back in for group to apply)"
else
    ok "Docker already installed: $(docker --version)"
fi

# Go
GO_VERSION="1.23.4"
if ! command -v go &>/dev/null; then
    info "Installing Go $GO_VERSION..."
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
    grep -qxF 'export PATH=$PATH:/usr/local/go/bin' "$HOME/.profile" || \
        echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.profile"
    ok "Go $GO_VERSION installed"
else
    ok "Go already installed: $(go version)"
fi

fi # end packages

# ─── 2. FiraCode Nerd Font ─────────────────────────────────────────────────────
if should_skip "font"; then skip "font -- skipped"; else

FONT_DIR="$HOME/.local/share/fonts"
if fc-list | grep -qi "FiraCode Nerd"; then
    ok "FiraCode Nerd Font already installed"
else
    info "Installing FiraCode Nerd Font..."
    mkdir -p "$FONT_DIR"
    FONT_ZIP="/tmp/FiraCode.zip"
    wget -q "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip" -O "$FONT_ZIP"
    unzip -q -o "$FONT_ZIP" -d "$FONT_DIR/FiraCode"
    rm "$FONT_ZIP"
    fc-cache -f
    ok "FiraCode Nerd Font installed"
fi

fi # end font

# ─── 3. Neovim config ─────────────────────────────────────────────────────────
if should_skip "nvim"; then skip "nvim -- skipped"; else

NVIM_SRC="$SCRIPT_DIR/nvim"
NVIM_DEST="$HOME/.config/nvim"

if [ -d "$NVIM_SRC" ]; then
    if [ -d "$NVIM_DEST" ]; then
        warn "Existing nvim config found — backing up to ${NVIM_DEST}.bak"
        rm -rf "${NVIM_DEST}.bak"
        mv "$NVIM_DEST" "${NVIM_DEST}.bak"
    fi
    cp -r "$NVIM_SRC" "$NVIM_DEST"
    ok "Neovim config copied to $NVIM_DEST"
else
    warn "nvim/ folder not found — run collect.sh on your Mac first"
fi

fi # end nvim

# ─── 4. .vscodevimrc ──────────────────────────────────────────────────────────
if should_skip "vscodevimrc"; then skip "vscodevimrc -- skipped"; else

VIMRC_SRC="$SCRIPT_DIR/.vscodevimrc"
if [ -f "$VIMRC_SRC" ]; then
    cp "$VIMRC_SRC" "$HOME/.vscodevimrc"
    ok ".vscodevimrc copied to $HOME"
else
    warn ".vscodevimrc not found in setup dir"
fi

fi # end vscodevimrc

# ─── 5. VS Code settings ──────────────────────────────────────────────────────
if should_skip "vscode-settings"; then skip "vscode-settings -- skipped"; else

VSCODE_USER="$HOME/.config/Code/User"
mkdir -p "$VSCODE_USER"

SETTINGS_SRC="$SCRIPT_DIR/vscode/settings.json"
KEYBINDINGS_SRC="$SCRIPT_DIR/vscode/keybindings.json"

if [ -f "$SETTINGS_SRC" ]; then
    cp "$SETTINGS_SRC" "$VSCODE_USER/settings.json"
    ok "VS Code settings.json copied"
else
    warn "vscode/settings.json not found"
fi

if [ -f "$KEYBINDINGS_SRC" ]; then
    cp "$KEYBINDINGS_SRC" "$VSCODE_USER/keybindings.json"
    ok "VS Code keybindings.json copied"
else
    warn "vscode/keybindings.json not found"
fi

fi # end vscode-settings

# ─── 6. VS Code extensions ────────────────────────────────────────────────────
if should_skip "vscode-extensions"; then skip "vscode-extensions -- skipped"; else

if ! command -v code &>/dev/null; then
    warn "VS Code CLI not found — skipping extensions. Open VS Code once then re-run."
else

EXTENSIONS=(
    "42crunch.vscode-openapi"
    "aaron-bond.better-comments"
    "adrianwilczynski.terminal-commands"
    "adrianwilczynski.toggle-hidden"
    "ahmadalli.vscode-nginx-conf"
    "anderseandersen.html-class-suggestions"
    "antfu.goto-alias"
    "anthropic.claude-code"
    "atomiks.moonlight"
    "bierner.markdown-mermaid"
    "bpruitt-goddard.mermaid-markdown-syntax-highlighting"
    "bradlc.vscode-tailwindcss"
    "chakrounanas.turbo-console-log"
    "christian-kohler.path-intellisense"
    "codezombiech.gitignore"
    "dariofuzinato.vue-peek"
    "davidanson.vscode-markdownlint"
    "dbaeumer.vscode-eslint"
    "digitalbrainstem.javascript-ejs-support"
    "docker.docker"
    "doggy8088.quicktype-refresh"
    "donjayamanne.githistory"
    "drblury.protobuf-vsc"
    "dsznajder.es7-react-js-snippets"
    "eamodio.gitlens"
    "editorconfig.editorconfig"
    "esbenp.prettier-vscode"
    "eserozvataf.one-dark-pro-monokai-darker"
    "formulahendry.auto-close-tag"
    "formulahendry.auto-rename-tag"
    "formulahendry.code-runner"
    "foxundermoon.shell-format"
    "franzgollhammer.jb-fleet-dark"
    "frhtylcn.pythonsnippets"
    "github.copilot-chat"
    "github.github-vscode-theme"
    "github.vscode-pull-request-github"
    "glenn2223.live-sass"
    "golang.go"
    "grapecity.gc-excelviewer"
    "james-yu.latex-workshop"
    "jebbs.plantuml"
    "jeremyrajan.webpack"
    "jripouteau.adonis-vscode-extension"
    "mads-hartmann.bash-ide-vscode"
    "mhutchie.git-graph"
    "mikestead.dotenv"
    "mongodb.mongodb-vscode"
    "mrmlnc.vscode-scss"
    "ms-azuretools.vscode-containers"
    "ms-azuretools.vscode-docker"
    "ms-kubernetes-tools.vscode-kubernetes-tools"
    "ms-python.black-formatter"
    "ms-python.debugpy"
    "ms-python.isort"
    "ms-python.python"
    "ms-python.vscode-pylance"
    "ms-python.vscode-python-envs"
    "ms-vscode-remote.remote-containers"
    "ms-vscode-remote.remote-ssh"
    "ms-vscode-remote.remote-ssh-edit"
    "ms-vscode.live-server"
    "ms-vscode.makefile-tools"
    "ms-vscode.remote-explorer"
    "natizyskunk.sftp"
    "naumovs.color-highlight"
    "neonxp.gotools"
    "nuxtr.nuxt-vscode-extentions"
    "nuxtr.nuxtr-vscode"
    "octref.vetur"
    "orta.vscode-jest"
    "pascalreitermann93.vscode-yaml-sort"
    "patbenatar.advanced-new-file"
    "pflannery.vscode-versionlens"
    "piotrpalarz.vscode-gitignore-generator"
    "pkief.material-icon-theme"
    "pomdtr.excalidraw-editor"
    "qhoekman.language-plantuml"
    "qvist.jetbrains-new-ui-dark-theme"
    "rangav.vscode-thunder-client"
    "redhat.vscode-community-server-connector"
    "redhat.vscode-rsp-ui"
    "redhat.vscode-xml"
    "redhat.vscode-yaml"
    "riazxrazor.html-to-jsx"
    "ritwickdey.liveserver"
    "romanrei.material-dark"
    "shd101wyy.markdown-preview-enhanced"
    "sibiraj-s.vscode-scss-formatter"
    "skyran.js-jsx-snippets"
    "sleistner.vscode-fileutils"
    "souche.vscode-mindmap"
    "standard.vscode-standard"
    "streetsidesoftware.code-spell-checker"
    "sumneko.lua"
    "thekalinga.bootstrap4-vscode"
    "vivaxy.vscode-conventional-commits"
    "vscode-icons-team.vscode-icons"
    "vscodevim.vim"
    "vue.volar"
    "wart.ariake-dark"
    "wayou.vscode-todo-highlight"
    "william-voyek.vscode-nginx"
    "wscats.eno"
    "xabikos.javascriptsnippets"
    "yzhang.markdown-all-in-one"
    "zainchen.json"
    "zenghongtu.vscode-asciiflow2"
    "zhuangtongfa.material-theme"
)

info "Installing VS Code extensions..."
for ext in "${EXTENSIONS[@]}"; do
    code --install-extension "$ext" --force 2>/dev/null
    ok "Extension: $ext"
done

fi

fi # end vscode-extensions

# ─── 7. zsh + oh-my-zsh + nvm + Node + Python + Go ───────────────────────────
if should_skip "zsh"; then skip "zsh -- skipped"; else

info "Running zsh setup..."
bash "$SCRIPT_DIR/zsh/install.sh"

fi # end zsh

# ─── 8. Mac-like keyboard (keyd) ──────────────────────────────────────────────
if should_skip "keymap"; then skip "keymap -- skipped"; else

# keyd requires a kernel module — install from source if not in apt
if ! command -v keyd &>/dev/null; then
    info "Installing keyd..."
    KEYD_TMP="/tmp/keyd-build"
    rm -rf "$KEYD_TMP"
    git clone https://github.com/rvaiya/keyd "$KEYD_TMP"
    cd "$KEYD_TMP"
    make
    sudo make install
    cd - > /dev/null
    rm -rf "$KEYD_TMP"
    sudo systemctl enable keyd
    ok "keyd installed"
else
    ok "keyd already installed"
fi

KEYD_CONF="/etc/keyd/default.conf"
KEYD_SRC="$SCRIPT_DIR/mac-keymap.keyd"

if [ -f "$KEYD_SRC" ]; then
    sudo mkdir -p /etc/keyd
    sudo cp "$KEYD_SRC" "$KEYD_CONF"
    sudo systemctl restart keyd
    ok "Mac keymap applied via keyd (Left Alt = Cmd, Super = Option)"
else
    warn "mac-keymap.keyd not found in setup dir"
fi

fi # end keymap

# ─── 9. Screenshot tool (Flameshot) ───────────────────────────────────────────
if should_skip "screenshot"; then skip "screenshot -- skipped"; else

if ! command -v flameshot &>/dev/null; then
    info "Installing Flameshot..."
    sudo apt-get install -y flameshot
    ok "Flameshot installed"
else
    ok "Flameshot already installed"
fi

# Bind Super+Shift+4 → flameshot gui   (like macOS Cmd+Shift+4 — area screenshot)
# Bind Super+Shift+5 → flameshot gui   (same; macOS Cmd+Shift+5 is the picker UI)
if command -v gsettings &>/dev/null; then
    info "Setting up screenshot shortcuts in GNOME..."

    # Find a free custom shortcut slot
    SLOT=0
    while gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding \
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${SLOT}/" \
        2>/dev/null | grep -q "flameshot"; do
        SLOT=$((SLOT + 1))
    done

    BASE="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${SLOT}/"

    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BASE" name "Flameshot area"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BASE" command "flameshot gui"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BASE" binding "<Super><Shift>s"

    # Register the new shortcut
    EXISTING=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
    if ! echo "$EXISTING" | grep -q "custom${SLOT}"; then
        NEW_LIST=$(echo "$EXISTING" | sed "s|]|, '${BASE}']|")
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_LIST"
    fi

    ok "Screenshot shortcut: Super+Shift+S → Flameshot area capture"
    ok "(If keyd is active, use Alt+Shift+4 — keyd maps Alt to Super)"
else
    warn "gsettings not found — set shortcut manually: Flameshot > Settings > Shortcuts"
fi

fi # end screenshot

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────────────────────────"
echo " Mac Keymap is active! Left Alt now works like Cmd key."
echo "─────────────────────────────────────────────────────────"
echo " Key layout:"
echo "   Left Alt  = Cmd  (copy, paste, save, undo, tabs...)"
echo "   Super key = Option (word-jump with Super+Left/Right)"
echo "   Left Ctrl = Ctrl (unchanged)"
echo ""
echo " Screenshots (GNOME):"
echo "   Print Screen           = Full screenshot"
echo "   Shift+Print Screen     = Area selection"
echo "   Super+Shift+S          = Flameshot area capture (Mac-like)"
echo ""
echo " To pause keymap: sudo systemctl stop keyd"
echo " To resume:       sudo systemctl start keyd"
echo ""
echo "All done! Log out and back in to apply group changes (Docker)."
echo "Restart VS Code to apply settings."
