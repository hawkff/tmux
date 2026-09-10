#!/usr/bin/env bash

recent_dirs_file="$HOME/.recent_dirs"

list_directories() {
    find "$1" -type d 2>/dev/null
}

choose_directory() {
    local PS3='Please select a directory: '
    local options=("Desktop" "Documents" "Downloads" "Recent Directories" "Enter a different path")
    local choice
    local custom_path

    select opt in "${options[@]}"; do
        case $opt in
            "Desktop"|"Documents"|"Downloads")
                choice=$(list_directories "$HOME/$opt" | fzf --height 40% --border || echo 'cancelled')
                ;;
            "Recent Directories")
                choice=$(tac "$recent_dirs_file" | awk '!seen[$0]++' | fzf --height 40% --border)
                ;;
            "Enter a different path")
                echo "Enter the full path (Tab for autocompletion):"
                read -r -e -p "Path: " custom_path
                if [[ -d "$custom_path" ]]; then
                    choice=$(list_directories "$custom_path" | fzf --height 40% --border || echo 'cancelled')
                else
                    echo "Invalid path: $custom_path"
                    exit 1
                fi
                ;;
            *) echo "Invalid option $REPLY";;
        esac

        if [[ $choice == 'cancelled' ]]; then
            return 1
        elif [[ -n $choice ]]; then
            break
        fi
    done

    echo "$choice"
}

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(choose_directory) || exit 0
fi

if [[ -z $selected ]]; then
    exit 0
fi

printf '%s\n' "$selected" >> "$recent_dirs_file"

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s "$selected_name" -c "$selected"
    exit 0
fi

if ! tmux has-session -t="$selected_name" 2> /dev/null; then
    tmux new-session -ds "$selected_name" -c "$selected"
fi

tmux switch-client -t "$selected_name"

