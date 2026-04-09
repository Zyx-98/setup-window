#!/bin/bash
# Run this INSIDE WSL2 (Ubuntu) after setup.ps1 completes
# Usage: bash /mnt/c/Users/<you>/mac-setup/zsh/install.sh

set -e

ok()   { echo -e "\033[32m[ OK ]\033[0m $1"; }
info() { echo -e "\033[36m[INFO]\033[0m $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 1. Install zsh ────────────────────────────────────────────────────────────
info "Installing zsh..."
sudo apt-get update -qq
sudo apt-get install -y zsh curl git
ok "zsh installed"

# ── 2. Install oh-my-zsh ──────────────────────────────────────────────────────
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing oh-my-zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ok "oh-my-zsh installed"
else
    ok "oh-my-zsh already installed"
fi

# ── 3. Install zsh-autosuggestions ───────────────────────────────────────────
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    ok "zsh-autosuggestions installed"
else
    ok "zsh-autosuggestions already installed"
fi

# ── 4. Install NVM + Node.js LTS ─────────────────────────────────────────────
if [ ! -d "$HOME/.nvm" ]; then
    info "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    ok "nvm installed"
else
    ok "nvm already installed"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
info "Installing Node.js LTS..."
nvm install --lts
nvm use --lts
ok "Node.js $(node -v) installed"

# ── 5. Install Python 3 + pip ─────────────────────────────────────────────────
info "Installing Python 3..."
sudo apt-get install -y python3 python3-pip python3-venv
ok "Python $(python3 --version) installed"

# ── 6. Install Go ─────────────────────────────────────────────────────────────
GO_VERSION="1.23.4"
if ! command -v go &>/dev/null; then
    info "Installing Go $GO_VERSION..."
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
    # Add to PATH in .zshrc (appended after copy, so we do it here)
    echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.profile"
    ok "Go $GO_VERSION installed"
else
    ok "Go already installed: $(go version)"
fi

# ── 7. Copy .zshrc ────────────────────────────────────────────────────────────
info "Copying .zshrc..."
cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
ok ".zshrc copied"

# ── 8. Set zsh as default shell ───────────────────────────────────────────────
info "Setting zsh as default shell..."
chsh -s $(which zsh)
ok "zsh is now the default shell"

echo ""
echo "All done! Close and reopen your WSL terminal to start using zsh."
