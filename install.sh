#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Ubuntu Dev Environment Setup ==="
echo ""

# --- 1. Install packages ---
echo "[1/8] Installing packages..."
sudo apt update
sudo apt install -y \
    zsh \
    curl \
    git \
    fonts-jetbrains-mono \
    tmux \
    xclip \
    fzf \
    ripgrep \
    npm

# Neovim — needs PPA for latest version (0.11+)
echo "  -> Adding neovim PPA for latest version..."
sudo add-apt-repository -y ppa:neovim-ppa/unstable
sudo apt update
sudo apt install -y neovim

# tree-sitter-cli — needed by nvim-treesitter
sudo npm install -g tree-sitter-cli

# --- 2. Set zsh as default shell ---
echo "[2/7] Setting zsh as default shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
    echo "  -> zsh set as default shell (log out and back in to take effect)"
else
    echo "  -> already using zsh"
fi

# --- 3. Install Oh My Zsh ---
echo "[3/7] Installing Oh My Zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "  -> already installed"
else
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# --- 4. Copy configs ---
echo "[4/7] Copying configs..."

# Ghostty
mkdir -p ~/.config/ghostty
cp "$SCRIPT_DIR/configs/ghostty.conf" ~/.config/ghostty/config
echo "  -> Ghostty config -> ~/.config/ghostty/config"

# tmux
cp "$SCRIPT_DIR/configs/tmux.conf" ~/.tmux.conf
echo "  -> tmux config -> ~/.tmux.conf"

# zshrc
cp "$SCRIPT_DIR/configs/zshrc" ~/.zshrc
echo "  -> zshrc -> ~/.zshrc"

# --- 5. Install TPM (Tmux Plugin Manager) ---
echo "[5/7] Installing TPM..."
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "  -> already installed"
else
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# --- 6. Install kickstart.nvim ---
echo "[6/8] Installing kickstart.nvim..."
if [ -d "$HOME/.config/nvim" ]; then
    echo "  -> neovim config already exists, skipping"
else
    git clone https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim
    echo "  -> kickstart.nvim -> ~/.config/nvim"
fi

# Apply our customizations on top of kickstart
echo "  -> Applying neovim customizations..."
cp "$SCRIPT_DIR/configs/nvim/init.lua" ~/.config/nvim/init.lua
cp "$SCRIPT_DIR/configs/nvim/lua/kickstart/plugins/neo-tree.lua" ~/.config/nvim/lua/kickstart/plugins/neo-tree.lua
echo "  -> init.lua (plugins enabled) + neo-tree.lua (Ctrl+n toggle)"

# --- 7. Install scripts ---
echo "[7/8] Installing scripts..."
mkdir -p ~/.local/bin

cp "$SCRIPT_DIR/dev" ~/.local/bin/dev
chmod +x ~/.local/bin/dev
echo "  -> dev -> ~/.local/bin/dev"

cp "$SCRIPT_DIR/tmux-sessionizer" ~/.local/bin/tmux-sessionizer
chmod +x ~/.local/bin/tmux-sessionizer
echo "  -> tmux-sessionizer -> ~/.local/bin/tmux-sessionizer"

# Make sure ~/.local/bin is in PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo "  -> WARNING: ~/.local/bin is not in your PATH. Add it to ~/.zshrc:"
    echo '     export PATH="$HOME/.local/bin:$PATH"'
fi

# --- 8. Final steps ---
echo "[8/8] Final steps..."
echo ""
echo "=== Setup complete! ==="
echo ""
echo "Manual steps remaining:"
echo "  1. Install Ghostty from https://ghostty.org (not in apt)"
echo "  2. Install Claude Code: npm install -g @anthropic-ai/claude-code"
echo "  3. Log out and back in (for zsh to take effect)"
echo "  4. Open tmux and press C-a I to install tmux plugins"
echo "  5. Open neovim once (nvim) to install plugins, then quit (:q)"
echo "  6. In ~/.config/nvim/init.lua, uncomment neo-tree and other plugins"
echo "  7. Type 'dev' to start your dev session"
echo ""
