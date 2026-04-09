#!/bin/bash
# Run this on your Mac to bundle your configs into this folder
# Usage: bash collect.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Collecting nvim config..."
rm -rf "$SCRIPT_DIR/nvim"
cp -r ~/.config/nvim "$SCRIPT_DIR/nvim"

echo "Collecting .vscodevimrc..."
cp ~/.vscodevimrc "$SCRIPT_DIR/.vscodevimrc" 2>/dev/null || touch "$SCRIPT_DIR/.vscodevimrc"

echo "Collecting .zshrc into zsh/..."
cp ~/.zshrc "$SCRIPT_DIR/zsh/.zshrc.mac"   # keep mac original for reference
# (zsh/.zshrc is the WSL-adapted version — do not overwrite it)

echo "Done. Zip the whole folder and bring it to Windows."
echo "On Windows, run: powershell -ExecutionPolicy Bypass -File setup.ps1"
