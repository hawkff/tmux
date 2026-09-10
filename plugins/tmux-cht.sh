#!/usr/bin/env bash

selected=$(cat ~/.config/tmux/custom/.tmux-cht-languages ~/.config/tmux/custom/.tmux-cht-command | fzf)
if [[ -z $selected ]]; then
    exit 0
fi

echo "selected $selected"

read -r -p "Enter the name of the cheat sheet: " query

if grep -qs "$selected" ~/.config/tmux/custom/.tmux-cht-languages; then
    tmux split-window -h bash -c "cht.sh \"$selected/$query\" | less -R"
else
    tmux split-window -h bash -c "cht.sh \"$selected $query\" | less -R"
fi
