# tmux

My private config of tmux

## Installation

```bash
# Clone this repo
git clone https://github.com/hawkff/tmux.git ~/.config/tmux

# Start tmux - TPM and plugins will auto-install
tmux
```

After plugins install, create the symlink for the custom RAM script:

```bash
ln -sf ~/.config/tmux/plugins/free-ram.sh ~/.config/tmux/plugins/tmux/scripts/free-ram.sh
```

## Manual TPM install (if auto-install fails)

```bash
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```

Then press `prefix + I` to install plugins.

## Key bindings

- `prefix` = `Ctrl+Space`
- `prefix + I` = Install plugins
- `prefix + r` = Reload config
- `prefix + f` = tmux-sessionizer
- `prefix + i` = cheat sheet
