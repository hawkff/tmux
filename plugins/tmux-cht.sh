#!/usr/bin/env bash

# Define the programming languages and core utilities
# languages=$(echo "golang c cpp swift rust typescript" | tr " " "\n")
# core_utils=$(echo "find xargs sed awk" | tr " " "\n")
selected=`cat ~/.config/tmux/custom/.tmux-cht-languages ~/.config/tmux/custom/.tmux-cht-command | fzf`
if [[ -z $selected ]]; then
    exit 0
fi

# Use fzf to select a language or utility
# selected=$(echo -e "$languages\n$core_utils" | fzf)
echo "selected $selected"

# Prompt for the cheat sheet query
read -p "Enter the name of the cheat sheet: " query

# Check if the selected item is a language or a core utility
# and use the local cht.sh client to fetch and display the cheat sheet
# if echo "$languages" | grep -qs "$selected"; then
    # tmux split-window -h bash -c "cht.sh \"$selected/$(echo \"$query\")\" | less -R"
# else
    # tmux split-window -h bash -c "cht.sh \"$selected $query\" | less -R"
# fi


if grep -qs "$selected" ~/.config/tmux/custom/.tmux-cht-languages; then
    tmux split-window -h bash -c "cht.sh \"$selected/$(echo \"$query\")\" | less -R"
else
    tmux split-window -h bash -c "cht.sh \"$selected $query\" | less -R"
fi


