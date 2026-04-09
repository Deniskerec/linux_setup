#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Ubuntu Dev Environment Setup ==="
echo ""

# --- 1. SSH key ---
echo "[1/10] SSH key setup..."
if [ -f "$HOME/.ssh/id_ed25519" ]; then
    echo "  -> SSH key already exists"
else
    ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f "$HOME/.ssh/id_ed25519" -N ""
    echo ""
    echo "========================================="
    echo "  Your new SSH public key:"
    echo "========================================="
    cat "$HOME/.ssh/id_ed25519.pub"
    echo ""
    echo "========================================="
    echo "  Add this key to GitHub:"
    echo "  https://github.com/settings/ssh/new"
    echo "========================================="
    echo ""
    read -p "Press ENTER after you've added the key to GitHub..."
fi

# Test GitHub connection
echo "  -> Testing GitHub SSH connection..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "  -> GitHub SSH connection works!"
else
    echo "  -> WARNING: GitHub SSH test didn't confirm. You may need to add the key."
    echo "     Key: $(cat ~/.ssh/id_ed25519.pub)"
    read -p "Press ENTER to continue anyway..."
fi

# --- 2. Install packages ---
echo "[2/10] Installing packages..."
sudo apt update
sudo apt install -y \
    zsh \
    curl \
    git \
    fonts-jetbrains-mono \
    tmux \
    xclip \
    fzf \
    ripgrep

# Neovim — needs PPA for latest version (0.11+)
echo "  -> Adding neovim PPA for latest version..."
sudo add-apt-repository -y ppa:neovim-ppa/unstable
sudo apt update
sudo apt install -y neovim

# --- 3. Install NVM + Node ---
echo "[3/10] Installing NVM + Node..."
if [ -d "$HOME/.nvm" ]; then
    echo "  -> NVM already installed"
else
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
echo "  -> Node $(node --version) installed"

# tree-sitter-cli — needed by nvim-treesitter
npm install -g tree-sitter-cli

# --- 4. Install Ghostty ---
echo "[4/10] Installing Ghostty..."
if command -v ghostty &>/dev/null; then
    echo "  -> Ghostty already installed"
else
    # Ghostty official apt repository
    curl -fsSL https://pkg.ghostty.org/pubkey.gpg | sudo tee /usr/share/keyrings/ghostty-archive-keyring.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/ghostty-archive-keyring.gpg] https://pkg.ghostty.org/apt stable main" | sudo tee /etc/apt/sources.list.d/ghostty.list
    sudo apt update
    sudo apt install -y ghostty
    echo "  -> Ghostty installed"
fi

# --- 5. Install Claude Code ---
echo "[5/10] Installing Claude Code..."
if command -v claude &>/dev/null; then
    echo "  -> Claude Code already installed"
else
    npm install -g @anthropic-ai/claude-code
    echo "  -> Claude Code installed"
fi

# --- 6. Set zsh as default shell ---
echo "[6/10] Setting zsh as default shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
    echo "  -> zsh set as default shell (takes effect after next login)"
else
    echo "  -> already using zsh"
fi

# --- 7. Install Oh My Zsh ---
echo "[7/10] Installing Oh My Zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "  -> already installed"
else
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# --- 8. Copy configs ---
echo "[8/10] Copying configs..."

# Ghostty
mkdir -p ~/.config/ghostty
cp "$SCRIPT_DIR/configs/ghostty.conf" ~/.config/ghostty/config
echo "  -> Ghostty config"

# tmux
cp "$SCRIPT_DIR/configs/tmux.conf" ~/.tmux.conf
echo "  -> tmux config"

# zshrc
cp "$SCRIPT_DIR/configs/zshrc" ~/.zshrc
echo "  -> zshrc"

# LazyVim
if [ -d "$HOME/.config/nvim" ]; then
    echo "  -> neovim config exists, backing up to ~/.config/nvim.bak"
    mv ~/.config/nvim ~/.config/nvim.bak.$(date +%s)
fi

mkdir -p ~/.config/nvim/lua/config
mkdir -p ~/.config/nvim/lua/plugins
cp "$SCRIPT_DIR/configs/nvim/init.lua" ~/.config/nvim/init.lua
cp "$SCRIPT_DIR/configs/nvim/lazyvim.json" ~/.config/nvim/lazyvim.json
cp "$SCRIPT_DIR/configs/nvim/lua/config/lazy.lua" ~/.config/nvim/lua/config/lazy.lua
cp "$SCRIPT_DIR/configs/nvim/lua/config/options.lua" ~/.config/nvim/lua/config/options.lua
cp "$SCRIPT_DIR/configs/nvim/lua/config/keymaps.lua" ~/.config/nvim/lua/config/keymaps.lua
cp "$SCRIPT_DIR/configs/nvim/lua/config/autocmds.lua" ~/.config/nvim/lua/config/autocmds.lua
cp "$SCRIPT_DIR/configs/nvim/lua/plugins/neo-tree.lua" ~/.config/nvim/lua/plugins/neo-tree.lua
cp "$SCRIPT_DIR/configs/nvim/lua/plugins/lang-java.lua" ~/.config/nvim/lua/plugins/lang-java.lua
cp "$SCRIPT_DIR/configs/nvim/lua/plugins/lang-sql.lua" ~/.config/nvim/lua/plugins/lang-sql.lua
echo "  -> LazyVim config"

# --- 9. Install scripts + plugins ---
echo "[9/10] Installing scripts and plugins..."

# Scripts
mkdir -p ~/.local/bin
cp "$SCRIPT_DIR/dev" ~/.local/bin/dev
chmod +x ~/.local/bin/dev
cp "$SCRIPT_DIR/tmux-sessionizer" ~/.local/bin/tmux-sessionizer
chmod +x ~/.local/bin/tmux-sessionizer
echo "  -> dev + tmux-sessionizer scripts"

# TPM (Tmux Plugin Manager) + install plugins
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "  -> TPM already installed"
else
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi
echo "  -> Installing tmux plugins..."
~/.tmux/plugins/tpm/bin/install_plugins
echo "  -> tmux plugins installed"

# LazyVim plugins — headless install
echo "  -> Installing neovim plugins (headless)..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
echo "  -> neovim plugins installed"

# --- 10. Claude Code multi-account ---
echo "[10/10] Setting up Claude Code..."
mkdir -p ~/.claude-private
echo "  -> ~/.claude-private created"

# --- Done ---
echo ""
echo "=== Setup complete! ==="
echo ""
echo "Next steps:"
echo "  1. Log out and back in (for zsh to take effect)"
echo "  2. Run 'claude' to log in to your work Claude account"
echo "  3. Run 'claude-private' to log in to your private Claude account"
echo "  4. Type 'dev' to start your dev session"
echo ""
echo "Aliases:"
echo "  dev             — tmux dev session (neovim + claude + terminal)"
echo "  tmux-clean      — wipe saved sessions and start fresh"
echo "  claude-work     — Claude with work account"
echo "  claude-private  — Claude with private account"
echo ""
