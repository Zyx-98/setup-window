#!/bin/bash
# Ubuntu Setup Script — No Mac keymap
# Like setup-ubuntu.sh but skips the keyd Mac-keymap step entirely.
# VS Code uses standard Ubuntu/Linux Ctrl-based shortcuts with
# vim h/j/k/l direction keys for power features (multi-cursor, move/duplicate line).
#
# Run on a fresh Ubuntu 22.04 / 24.04 desktop:
#   bash setup-ubuntu-nokeymap.sh
#
# To skip additional steps, set SKIP before running:
#   SKIP="terminal emoji" bash setup-ubuntu-nokeymap.sh
#
# Available skip keys (keymap is always skipped in this script):
#   packages          - apt package installs
#   font              - FiraCode Nerd Font
#   nvim              - Neovim config copy
#   vscodevimrc       - .vscodevimrc copy
#   vscode-settings   - VS Code settings + keybindings
#   vscode-extensions - VS Code extension installs
#   zsh               - zsh/oh-my-zsh + nvm + Node + Python + Go setup
#   screenshot        - Flameshot + shortcut binding
#   terminal          - Ghostty terminal emulator
#   emoji             - Smile emoji picker + Super+. shortcut

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

SETTINGS_SRC="$SCRIPT_DIR/vscode/settings-ubuntu.json"
KEYBINDINGS_SRC="$SCRIPT_DIR/vscode/keybindings-ubuntu-nokeymap.json"

if [ -f "$SETTINGS_SRC" ]; then
    cp "$SETTINGS_SRC" "$VSCODE_USER/settings.json"
    ok "VS Code settings.json copied"
else
    warn "vscode/settings-ubuntu.json not found"
fi

if [ -f "$KEYBINDINGS_SRC" ]; then
    cp "$KEYBINDINGS_SRC" "$VSCODE_USER/keybindings.json"
    ok "VS Code keybindings.json copied (ubuntu-nokeymap)"
else
    warn "vscode/keybindings-ubuntu-nokeymap.json not found"
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

info "Fetching installed extensions list..."
INSTALLED_EXTS=$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')

EXT_INSTALLED=0
EXT_SKIPPED=0
EXT_FAILED=0

for ext in "${EXTENSIONS[@]}"; do
    ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    if echo "$INSTALLED_EXTS" | grep -qx "$ext_lower"; then
        skip "Already installed: $ext"
        EXT_SKIPPED=$((EXT_SKIPPED + 1))
        continue
    fi

    if code --install-extension "$ext" --force > /dev/null 2>&1; then
        ok "Installed: $ext"
        EXT_INSTALLED=$((EXT_INSTALLED + 1))
    else
        warn "Failed (skipping): $ext"
        EXT_FAILED=$((EXT_FAILED + 1))
    fi
done

echo ""
ok "Extensions done — installed: $EXT_INSTALLED, already existed: $EXT_SKIPPED, failed: $EXT_FAILED"

fi

fi # end vscode-extensions

# ─── 7. zsh + oh-my-zsh + nvm + Node + Python + Go ───────────────────────────
if should_skip "zsh"; then skip "zsh -- skipped"; else

info "Running zsh setup..."
bash "$SCRIPT_DIR/zsh/install.sh"

fi # end zsh

# ─── 8. Screenshot + Screen Recording ────────────────────────────────────────
if should_skip "screenshot"; then skip "screenshot -- skipped"; else

# Flameshot — area screenshot
if ! command -v flameshot &>/dev/null; then
    info "Installing Flameshot..."
    sudo apt-get install -y flameshot
    ok "Flameshot installed"
else
    ok "Flameshot already installed"
fi

# Kooha — simple screen recorder
if ! command -v kooha &>/dev/null; then
    info "Installing Kooha (screen recorder)..."
    if command -v flatpak &>/dev/null; then
        flatpak install -y flathub io.github.seadve.Kooha 2>/dev/null && ok "Kooha installed" \
            || warn "Kooha install failed — install manually from Flathub or use GNOME's built-in Ctrl+Alt+Shift+R"
    else
        sudo apt-get install -y flatpak
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        flatpak install -y flathub io.github.seadve.Kooha 2>/dev/null && ok "Kooha installed" \
            || warn "Kooha install failed — install manually from Flathub or use GNOME's built-in Ctrl+Alt+Shift+R"
    fi
else
    ok "Kooha already installed"
fi

if command -v gsettings &>/dev/null; then
    info "Binding screenshot and screen-recorder shortcuts in GNOME..."

    bind_shortcut() {
        local name="$1" cmd="$2" key="$3"
        local slot=0
        while true; do
            local base="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${slot}/"
            local existing_cmd
            existing_cmd=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$base" command 2>/dev/null || true)
            if echo "$existing_cmd" | grep -q "$cmd"; then break; fi
            if [ -z "$existing_cmd" ] || [ "$existing_cmd" = "''" ]; then break; fi
            slot=$((slot + 1))
        done

        local base="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${slot}/"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$base" name    "$name"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$base" command "$cmd"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$base" binding "$key"

        local existing_list
        existing_list=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
        if ! echo "$existing_list" | grep -q "custom${slot}/"; then
            local new_list
            if echo "$existing_list" | grep -qE '^\@?a?s?\s*\[\s*\]$'; then
                new_list="['${base}']"
            else
                new_list=$(echo "$existing_list" | sed "s|]$|, '${base}']|")
            fi
            gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_list"
        fi

        ok "Bound: $key → $cmd"
    }

    # Use Print Screen combos directly (no keyd to remap Alt)
    bind_shortcut "Screenshot area"  "flameshot gui"                        "<Shift>Print"
    KOOHA_CMD="flatpak run io.github.seadve.Kooha"
    command -v kooha &>/dev/null && KOOHA_CMD="kooha"
    bind_shortcut "Screen recorder"  "$KOOHA_CMD"                           "<Control><Shift>Print"
else
    warn "gsettings not found — set shortcuts manually in GNOME Settings > Keyboard"
fi

fi # end screenshot

# ─── 9. Terminal emulator (Ghostty) ───────────────────────────────────────────
if should_skip "terminal"; then skip "terminal -- skipped"; else

if command -v ghostty &>/dev/null; then
    ok "Ghostty already installed: $(ghostty --version 2>/dev/null | head -1)"
else
    info "Installing Ghostty..."

    GHOSTTY_DEB="/tmp/ghostty.deb"
    GHOSTTY_RELEASE=$(curl -fsSL "https://api.github.com/repos/ghostty-org/ghostty/releases/latest" \
        | grep '"browser_download_url"' \
        | grep 'ubuntu' \
        | grep '\.deb"' \
        | head -1 \
        | sed 's/.*"\(https[^"]*\)".*/\1/')

    if [ -n "$GHOSTTY_RELEASE" ]; then
        wget -q "$GHOSTTY_RELEASE" -O "$GHOSTTY_DEB"
        sudo apt-get install -y "$GHOSTTY_DEB"
        rm -f "$GHOSTTY_DEB"
        ok "Ghostty installed"
    else
        warn "No .deb release found — trying snap..."
        if snap install ghostty --classic 2>/dev/null; then
            ok "Ghostty installed via snap"
        else
            warn "Ghostty install failed — install manually: https://ghostty.org/download"
        fi
    fi
fi

fi # end terminal

# ─── 10. Emoji picker (Smile) ─────────────────────────────────────────────────
if should_skip "emoji"; then skip "emoji -- skipped"; else

if ! flatpak list 2>/dev/null | grep -q "it.mijorus.smile"; then
    info "Installing Smile emoji picker..."
    if ! command -v flatpak &>/dev/null; then
        sudo apt-get install -y flatpak
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi
    flatpak install -y flathub it.mijorus.smile 2>/dev/null \
        && ok "Smile emoji picker installed" \
        || warn "Smile install failed — emoji picker won't be available"
else
    ok "Smile emoji picker already installed"
fi

# Bind Super+. → Smile (standard GNOME shortcut, no keyd needed)
if command -v gsettings &>/dev/null; then
    info "Binding Super+. to Smile emoji picker..."

    SMILE_CMD="flatpak run it.mijorus.smile"
    SLOT=0
    while true; do
        BASE="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${SLOT}/"
        existing_cmd=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BASE" command 2>/dev/null || true)
        if echo "$existing_cmd" | grep -q "smile"; then break; fi
        if [ -z "$existing_cmd" ] || [ "$existing_cmd" = "''" ]; then break; fi
        SLOT=$((SLOT + 1))
    done

    BASE="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${SLOT}/"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BASE" name    "Emoji picker"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BASE" command "$SMILE_CMD"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BASE" binding "<Super>period"

    EXISTING_LIST=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
    if ! echo "$EXISTING_LIST" | grep -q "custom${SLOT}/"; then
        if echo "$EXISTING_LIST" | grep -qE '^\@?a?s?\s*\[\s*\]$'; then
            NEW_LIST="['${BASE}']"
        else
            NEW_LIST=$(echo "$EXISTING_LIST" | sed "s|]$|, '${BASE}']|")
        fi
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_LIST"
    fi

    ok "Bound: Super+. → Smile emoji picker"
else
    warn "gsettings not found — set shortcut manually: Super+. → Smile"
fi

fi # end emoji

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────────────────────────────────────"
echo " Setup complete! Standard Ubuntu keyboard shortcuts are active."
echo "─────────────────────────────────────────────────────────────────────"
echo " VS Code standard shortcuts (Ubuntu/Linux defaults):"
echo "   Ctrl+C/V/X          = copy / paste / cut"
echo "   Ctrl+Z / Ctrl+Y     = undo / redo"
echo "   Ctrl+S              = save"
echo "   Ctrl+P              = quick open file"
echo "   Ctrl+Shift+P        = command palette"
echo "   Ctrl+F / Ctrl+Shift+F = find / find in files"
echo "   Ctrl+W              = close editor tab"
echo "   Ctrl+B              = toggle sidebar"
echo "   Ctrl+1..9           = switch to editor tab"
echo "   Ctrl+\`              = toggle terminal"
echo ""
echo " VS Code vim h/j/k/l shortcuts (custom — keybindings-ubuntu-nokeymap.json):"
echo "   Alt+j / Alt+k           = move line down / up"
echo "   Shift+Alt+j / Shift+Alt+k = duplicate line down / up"
echo "   Ctrl+Alt+j / Ctrl+Alt+k = add cursor below / above  (multi-cursor)"
echo "   Ctrl+Alt+h / Ctrl+Alt+l = focus left / right editor group"
echo "   Ctrl+Shift+Alt+h/j/k/l  = move editor to adjacent group"
echo "   Ctrl+Shift+h/j/k/l      = resize pane (Vim Normal mode only)"
echo "   Ctrl+j / Ctrl+k         = navigate suggest/quickpick list"
echo "   Ctrl+.                  = trigger suggest"
echo "   Ctrl+Alt+-              = go to definition"
echo ""
echo " Screenshots:"
echo "   Print Screen           = full screenshot (GNOME built-in)"
echo "   Shift+Print Screen     = area screenshot (Flameshot)"
echo "   Ctrl+Shift+Print Screen = screen recorder (Kooha)"
echo ""
echo " Emoji:  Super+.  → Smile picker"
echo ""
echo "All done! Log out and back in to apply group changes (Docker)."
echo "Restart VS Code to apply settings."
