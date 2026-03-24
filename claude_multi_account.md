# Claude Code — Multiple Account Setup

Switch between personal and work (Ridango) Claude accounts using separate config directories.

## Setup

Add these aliases to your `~/.zshrc`:

```bash
# Claude Code profiles
alias claude-personal="CLAUDE_CONFIG_DIR=~/.claude-personal claude"
alias claude-ridango="CLAUDE_CONFIG_DIR=~/.claude-ridango claude"
```

Reload your shell:

```bash
source ~/.zshrc
```

## First-time login

Each profile needs a one-time login:

```bash
claude-personal   # logs in with your personal account
claude-ridango    # logs in with your Ridango account
```

After that, each alias remembers its own session.

## Usage

```bash
claude-personal   # opens Claude with personal account
claude-ridango    # opens Claude with Ridango account
```

Both profiles keep separate settings, history, and auth tokens.
