# Ubuntu Dev Environment Setup

## Overview
Modern, minimal terminal setup for neovim + tmux on Ubuntu.

## Quick Install (New Machine)
```bash
git clone git@github-personal:Deniskerec/linux_setup.git
cd linux_setup
./install.sh
```
This installs all packages, copies all configs, and sets up scripts. See manual steps printed at the end.

### Repo Structure
```
configs/
  ghostty.conf                        -> ~/.config/ghostty/config
  tmux.conf                           -> ~/.tmux.conf
  zshrc                               -> ~/.zshrc
  nvim/init.lua                       -> ~/.config/nvim/init.lua
  nvim/lua/kickstart/plugins/neo-tree.lua -> ~/.config/nvim/lua/kickstart/plugins/neo-tree.lua
dev                                   -> ~/.local/bin/dev
tmux-sessionizer                      -> ~/.local/bin/tmux-sessionizer
install.sh                            — one-command setup
```

---

## 1. Install Prerequisites
```bash
sudo apt install fonts-jetbrains-mono zsh curl git
```

## 2. Install Ghostty
Download from https://ghostty.org and install.

## 3. Ghostty Config
Create the file `~/.config/ghostty/config` (NOT `config.ghostty`):

```
# Font
font-family = JetBrains Mono
font-size = 13
font-thicken = true
adjust-cell-height = 2

# Theme
theme = Catppuccin Mocha
background-opacity = 0.85
background-blur-radius = 30

# Window
window-padding-x = 16
window-padding-y = 10
window-padding-balance = true
window-padding-color = extend
window-decoration = true
confirm-close-surface = false
gtk-titlebar = true

# Cursor
cursor-style = block
cursor-style-blink = false
cursor-color = #f5e0dc

# Mouse
mouse-hide-while-typing = true

# Clipboard
copy-on-select = clipboard
clipboard-paste-protection = false

# Bold is bright
bold-is-bright = true

# Shell
command = /usr/bin/zsh

# Shell integration
shell-integration = detect

# Neovim/tmux compatibility
window-inherit-working-directory = true
```

## 4. Oh My Zsh Setup
```bash
# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Set zsh as default shell
chsh -s $(which zsh)
```
- **Theme**: robbyrussell (default — same as ThePrimeagen)
- Config: `~/.zshrc` — change `ZSH_THEME="robbyrussell"` to switch themes

## 5. Ghostty Keyboard Shortcuts
| Action | Shortcut |
|--------|----------|
| New window | `Ctrl+Shift+N` |
| New tab | `Ctrl+Shift+T` |
| Close tab/window | `Ctrl+Shift+W` |
| Quit Ghostty | `Ctrl+Shift+Q` |

---

## 6. tmux Setup (ThePrimeagen-inspired)

### Install
```bash
sudo apt install tmux xclip fzf
```

### Plugin Manager (TPM)
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```
After creating the config below, open tmux and press `C-a I` (capital I) to install plugins.

### Config
Create `~/.tmux.conf`:

```bash
# ===========================================
# ThePrimeagen-inspired tmux config
# ===========================================

# Fix colors and enable true color
set -ga terminal-overrides ",screen-256color*:Tc"
set-option -g default-terminal "screen-256color"

# Allow extended keys (fixes Shift+Enter in Claude Code, neovim, etc.)
set -s extended-keys on
set -as terminal-features 'xterm*:extkeys'

# Use zsh (fixes Oh My Zsh not loading inside tmux)
set-option -g default-shell /usr/bin/zsh

# No delay after pressing Escape (critical for neovim)
set -s escape-time 0

# Remap prefix from C-b to C-a
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Reload config with prefix + r
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Windows start at 1, not 0
set -g base-index 1
set-window-option -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Vi mode for copy
set-window-option -g mode-keys vi
bind -T copy-mode-vi v send-keys -X begin-selection
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'

# Vim-like pane switching
bind -r ^ last-window
bind -r k select-pane -U
bind -r j select-pane -D
bind -r h select-pane -L
bind -r l select-pane -R

# Quick pane resize (prefix + Shift h/j/k/l)
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Split panes with | and - (in current path)
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# New window in current path
bind c new-window -c "#{pane_current_path}"

# Mouse support
set -g mouse on

# Increase scrollback
set -g history-limit 50000

# Sessionizer — fuzzy-switch projects (C-a f)
bind-key -r f run-shell "tmux neww ~/.local/bin/tmux-sessionizer"

# ===========================================
# Status bar (Catppuccin Mocha inspired)
# ===========================================
set -g status-position bottom
set -g status-interval 5
set -g status-left-length 40
set -g status-right-length 60
set -g status-style 'bg=#1e1e2e fg=#cdd6f4'
set -g status-left '#[bg=#89b4fa,fg=#1e1e2e,bold] #S #[bg=#1e1e2e] '
set -g status-right '#[fg=#a6adc8]%H:%M  %d-%b-%Y '
set -g window-status-format '#[fg=#6c7086] #I:#W '
set -g window-status-current-format '#[bg=#333333,fg=#89b4fa,bold] #I:#W '

# ===========================================
# Plugins (via TPM)
# ===========================================
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# Resurrect — saves/restores pane contents
set -g @resurrect-capture-pane-contents 'on'

# Continuum — auto-save every 15 min, auto-restore on tmux start
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'

# Initialize TPM (keep at very bottom)
run '~/.tmux/plugins/tpm/tpm'
```

### tmux-sessionizer
Fuzzy-find a project directory and jump to a dedicated tmux session for it.
Saved at `~/.local/bin/tmux-sessionizer`:

```bash
#!/usr/bin/env bash
# Fuzzy-find a project and open a 3-window session for it.

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(find ~/Documents ~/projects ~ -mindepth 1 -maxdepth 1 -type d 2>/dev/null | fzf)
fi

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

# Create the 3-window layout if session doesn't exist
create_session() {
    tmux new-session -ds "$selected_name" -n "neovim" -c "$selected"
    tmux new-window -t "$selected_name:2" -n "claude" -c "$selected"
    tmux new-window -t "$selected_name:3" -n "terminal" -c "$selected"
    tmux select-window -t "$selected_name:1"
}

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    create_session
    tmux attach-session -t "$selected_name"
    exit 0
fi

if ! tmux has-session -t="$selected_name" 2>/dev/null; then
    create_session
fi

tmux switch-client -t "$selected_name"
```
Usage: press `C-a f` inside tmux, pick a folder — opens with 3 windows (neovim, claude, terminal).

### Dev Session Launcher
Saved at `~/.local/bin/dev` — just type `dev` from any directory to start.
All 3 windows open in the directory you launched from (e.g. `cd ~/projects/myapp && dev`).

```bash
#!/usr/bin/env bash
# Dev session launcher — starts tmux with 3 windows:
#   1: neovim (empty)   2: claude   3: terminal

SESSION="dev"

# If already in the session, bail
if tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux attach-session -t "$SESSION"
    exit 0
fi

# Create session with first window: neovim (empty shell)
tmux new-session -d -s "$SESSION" -n "neovim" -c "$(pwd)"

# Window 2: claude
tmux new-window -t "$SESSION:2" -n "claude" -c "$(pwd)"

# Window 3: terminal
tmux new-window -t "$SESSION:3" -n "terminal" -c "$(pwd)"

# Start on window 1 (nvim)
tmux select-window -t "$SESSION:1"

# Attach
tmux attach-session -t "$SESSION"
```

### Session Management

| What you want | Command |
|---|---|
| Start/reattach dev session | `dev` |
| Detach (keep running in background) | `C-a d` |
| List all sessions | `tmux ls` |
| Kill the dev session | `tmux kill-session -t dev` |
| Kill ALL sessions | `tmux kill-server` |

### tmux Keyboard Shortcuts
Prefix is `Ctrl+a` (not the default `Ctrl+b`).

| Action | Shortcut |
|--------|----------|
| Switch to window 1/2/3 | `C-a 1` / `C-a 2` / `C-a 3` |
| Last window | `C-a ^` |
| New window | `C-a c` |
| Split horizontal | `C-a \|` |
| Split vertical | `C-a -` |
| Pane left/down/up/right | `C-a h` / `C-a j` / `C-a k` / `C-a l` |
| Resize pane left/down/up/right | `C-a H` / `C-a J` / `C-a K` / `C-a L` |
| Sessionizer (fuzzy project switch) | `C-a f` |
| Reload config | `C-a r` |
| Copy mode (vi) | `C-a [` then `v` to select, `y` to yank |
| Detach | `C-a d` |
| Kill pane | `C-a x` |
| Install TPM plugins | `C-a I` (capital I) |

---

## 7. Neovim Setup (kickstart.nvim)

### Install
```bash
# Install neovim (needs PPA for latest 0.11+ — apt default is too old)
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update
sudo apt install neovim

# tree-sitter-cli (needed by nvim-treesitter for syntax highlighting)
sudo npm install -g tree-sitter-cli

# ripgrep (needed by telescope for live grep / search in files)
sudo apt install ripgrep

# Clone kickstart.nvim (minimal, batteries-included starter config)
git clone https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim
```

### First Launch
Open neovim once to auto-install all plugins:
```bash
nvim
```
Wait for downloads to finish, then quit with `:q`.

### Enable Bundled Plugins
Edit `~/.config/nvim/init.lua` and uncomment these lines (~line 912):
```lua
  require 'kickstart.plugins.indent_line',
  require 'kickstart.plugins.autopairs',
  require 'kickstart.plugins.neo-tree',
  require 'kickstart.plugins.gitsigns',
```

### File Explorer (Neo-tree)
Press `Ctrl+n` to toggle the file explorer sidebar.

| Action (inside Neo-tree) | Key |
|---|---|
| Open file | `Enter` |
| Open in split | `S` |
| Open in vsplit | `s` |
| Toggle hidden files | `H` |
| Create file/folder | `a` |
| Delete | `d` |
| Rename | `r` |
| Copy | `c` |
| Paste | `p` |
| Close explorer | `Ctrl+n` |

### Neovim Keyboard Shortcuts (kickstart defaults)

**File Navigation:**

| Action | Shortcut |
|--------|----------|
| File explorer toggle | `Ctrl+n` |
| Fuzzy find files | `<Space>sf` |
| Fuzzy grep (search in files) | `<Space>sg` |
| Switch open buffers | `<Space><Space>` (double space) |
| Recent files | `<Space>s.` |
| Jump between explorer and file | `Ctrl+w h` / `Ctrl+w l` |

**Code Navigation (requires LSP):**

| Action | Shortcut |
|--------|----------|
| Go to definition | `gd` |
| Go to declaration | `gD` |
| Go to implementation | `gi` |
| Find all references (usages) | `gr` |
| Hover docs | `K` |
| Go back | `Ctrl+o` |
| Go forward | `Ctrl+i` |

**Code Editing:**

| Action | Shortcut |
|--------|----------|
| Rename symbol | `<Space>rn` |
| Code action (quick fix) | `<Space>ca` |
| Format file | `<Space>f` |
| Next diagnostic | `]d` |
| Previous diagnostic | `[d` |
| Find & replace in file | `:%s/old/new/g` |

**Basics:**

| Action | Shortcut |
|--------|----------|
| Undo | `u` |
| Redo | `Ctrl+r` |
| Save | `:w` |
| Quit | `:q` |
| Save + quit | `:wq` |
| Delete line | `dd` |
| Copy line | `yy` |
| Paste | `p` |
| Select text | `v` + move cursor |
| Top of file | `gg` |
| Bottom of file | `G` |
| Go to line 42 | `42G` |
| Search in file | `/something` then `n` for next |

`<Space>` is the leader key. Press it and wait — a popup shows all available commands.

### LSP Servers (auto-installed via Mason)
- **pyright** — Python
- **ts_ls** — TypeScript/JavaScript
- **jdtls** — Java
- **sqlls** — SQL
- **lua_ls** — Lua

These enable go-to-definition, find references, hover docs, rename, etc. for each language.

---

## Gotchas
- Ghostty does **NOT** hot-reload config — restart the terminal to apply changes.
- Theme names use spaces and capitals (e.g. `Catppuccin Mocha`, not `catppuccin-mocha`).
- To list available themes: `ls /usr/share/ghostty/themes/`
- If zsh doesn't load, make sure `command = /usr/bin/zsh` is in the Ghostty config — it may default to bash.
- If Oh My Zsh doesn't load inside tmux, make sure `set-option -g default-shell /usr/bin/zsh` is in `~/.tmux.conf`.
- tmux prefix is `C-a` (ThePrimeagen style), NOT the default `C-b`.
- After editing `~/.tmux.conf`, reload with `C-a r` or `tmux source-file ~/.tmux.conf`.
- After adding the config, press `C-a I` inside tmux to install TPM plugins (resurrect + continuum).
- tmux-resurrect: manually save with `C-a Ctrl+s`, restore with `C-a Ctrl+r`.
- tmux-continuum auto-saves every 15 min and auto-restores on tmux start — sessions survive reboots.
- The sessionizer (`C-a f`) scans `~/Documents`, `~/projects`, and `~` — edit `~/.local/bin/tmux-sessionizer` to add more directories.
- If Shift+Enter doesn't work in Claude Code inside tmux, make sure `extended-keys` is in the config and **kill tmux fully** (`tmux kill-server`) then restart — `C-a r` reload is not enough for this setting.
- To select/copy text with mouse inside tmux, hold `Shift` while clicking and dragging — this bypasses tmux mouse mode.
- First time opening neovim takes a while — it downloads all plugins. Let it finish.
- If neovim looks broken, run `:Lazy sync` inside neovim to re-sync plugins.
- Press `<Space>` (leader key) and wait — a popup shows all available commands.
- Neo-tree file explorer toggles with `Ctrl+n`.
- To jump between explorer and file: `Ctrl+w h` (left) and `Ctrl+w l` (right).
- Switch between open files with `<Space><Space>` (double space — fuzzy buffer list).
- Ubuntu apt neovim is too old (0.9) — must use PPA for 0.11+.
