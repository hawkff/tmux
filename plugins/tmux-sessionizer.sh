#!/usr/bin/env bash

recent_dirs_file="$HOME/.recent_dirs"

log_recent_dir() {
    echo "$1" >> "$recent_dirs_file"
}

choose_recent_dir() {
    cat "$recent_dirs_file" | tac | awk '!seen[$0]++' | fzf --height 40% --border
}

list_directories() {
    local start_dir="$1"
    find "$start_dir" -type d 2>/dev/null & # Run find in background
    echo "Loading directories... (Press Ctrl-C to cancel)"
    wait # Wait for find to complete
}

choose_directory() {
    local PS3='Please select a directory: '
    local options=("Desktop" "Documents" "Downloads" "Recent Directories" "Enter a different path")
    local home_path="$HOME"
    local choice
    local custom_path

    select opt in "${options[@]}"; do
        case $opt in
            "Desktop"|"Documents"|"Downloads")
                choice=$(list_directories "$home_path/$opt" | fzf --height 40% --border || echo 'cancelled')
                ;;
            "Recent Directories")
                choice=$(choose_recent_dir)
                ;;
            "Enter a different path")
                echo "Enter the full path (Tab for autocompletion):"
                read -e -p "Path: " custom_path
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

log_recent_dir "$selected"

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

