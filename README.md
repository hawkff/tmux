# tmux

My private config of tmux

## Installation

```bash
git clone https://github.com/hawkff/tmux.git ~/.config/tmux
```

After plugins install, create the symlinks for the custom CPU/RAM scripts:

```bash
# free-ram.sh is a custom: plugin; cpu.sh replaces dracula's cpu_info.sh
# (so it keeps the orange cpu-usage colors)
ln -sf ~/.config/tmux/plugins/free-ram.sh ~/.config/tmux/plugins/tmux/scripts/free-ram.sh
ln -sf ~/.config/tmux/plugins/cpu.sh ~/.config/tmux/plugins/tmux/scripts/cpu_info.sh
cd ~/.config/tmux/plugins/tmux && git update-index --skip-worktree scripts/cpu_info.sh
```

On Apple Silicon, install [macmon](https://github.com/vladkens/macmon) + jq for
precise CPU usage and temperature (falls back to `top` without them):

```bash
brew install macmon jq
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
