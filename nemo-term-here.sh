#!/bin/bash

# Smart terminal launcher that opens in Nemo's current directory
# Built to allow ctrl+alt+t to pick up the directory that might be most relevant to what you're doing
# See README.md for instructions on how to configure Cinnamon's keyboard shortcut
# Falls back to normal terminal if no Nemo window is active

# Get all Nemo windows with full path titles (skip nemo-desktop and bare "nemo")
get_nemo_directories() {
    for id in $(xdotool search --class "nemo" 2>/dev/null); do
        title=$(xdotool getwindowname "$id" 2>/dev/null)
        # Skip desktop windows and empty/background processes
        if [[ "$title" == "nemo-desktop" || "$title" == "Desktop" || "$title" == "nemo" ]]; then
            continue
        fi
        # Extract path from format: "folder_name - /full/path"
        if [[ "$title" =~ ^.+\ -\ (/.*) ]]; then
            echo "${BASH_REMATCH[1]}:$id"
        fi
    done
}

# Get the most recently active nemo directory
get_active_nemo_directory() {
    # Step 1: Check if any Nemo windows are open at all
    local nemo_dirs=$(get_nemo_directories)
    if [[ -z "$nemo_dirs" ]]; then
        echo "NO_NEMO_OPEN"
        return
    fi
    
    # Step 2: Check if currently active window is a Nemo window
    local active_window=$(xdotool getactivewindow 2>/dev/null)
    if [[ -n "$active_window" ]]; then
        for entry in $nemo_dirs; do
            local path="${entry%:*}"
            local window_id="${entry#*:}"
            if [[ "$window_id" == "$active_window" ]]; then
                echo "$path"
                return
            fi
        done
    fi
    
    # Step 3: Find most recently focused Nemo window in stacking order
    # Get windows in actual stacking order (most recent last)
    local all_windows=$(xprop -root _NET_CLIENT_LIST_STACKING | grep -o '0x[0-9a-f]*' | tac)
    for window_hex in $all_windows; do
        window_hex=${window_hex#0x}  # Remove 0x prefix
        local window_dec=$((16#$window_hex))
        for entry in $nemo_dirs; do
            local path="${entry%:*}"
            local entry_id="${entry#*:}"
            if [[ "$entry_id" == "$window_dec" ]]; then
                echo "$path"
                return
            fi
        done
    done
    
    # Step 4: If we get here, something went wrong
    echo "ERROR_STACK_FAILED"
}

# Get default terminal
get_default_terminal() {
    # Try Cinnamon/GNOME settings first
    local default_term=$(gsettings get org.cinnamon.desktop.default-applications.terminal exec 2>/dev/null | tr -d "'")
    if [[ -n "$default_term" && "$default_term" != "No such key" ]]; then
        echo "$default_term"
        return
    fi
    
    # Fallback to TERMINAL env var
    if [[ -n "$TERMINAL" ]]; then
        echo "$TERMINAL"
        return
    fi
    
    # Final fallback
    echo "gnome-terminal"
}

# Launch terminal and focus the new window
launch_and_focus() {
    local dir="$1"

    # Snapshot all visible window IDs before launch
    local before
    before=$(xdotool search --onlyvisible --name '' 2>/dev/null | sort -n)

    # Launch terminal in specified directory (or current if empty)
    if [[ -n "$dir" ]]; then
        cd "$dir"
    fi
    $terminal_cmd &

    # Wait for new window to appear and focus it (up to 3s)
    for i in {1..30}; do
        sleep 0.1
        local after
        after=$(xdotool search --onlyvisible --name '' 2>/dev/null | sort -n)
        local new_window
        new_window=$(comm -13 <(echo "$before") <(echo "$after") | tail -1)
        if [[ -n "$new_window" ]]; then
            xdotool windowactivate --sync "$new_window" 2>/dev/null
            xdotool windowfocus --sync "$new_window" 2>/dev/null
            return 0
        fi
    done
    return 1
}

# Main logic
nemo_dir=$(get_active_nemo_directory)
terminal_cmd=$(get_default_terminal)

case "$nemo_dir" in
    "NO_NEMO_OPEN")
        echo "No Nemo windows open, or home is open, launching $terminal_cmd in home"
        launch_and_focus ""
        ;;
    "ERROR_STACK_FAILED")
        echo "ERROR: Nemo windows found but couldn't determine directory from stack"
        launch_and_focus ""
        ;;
    *)
        if [[ -d "$nemo_dir" ]]; then
            echo "Opening $terminal_cmd in: $nemo_dir"
            launch_and_focus "$nemo_dir"
        else
            echo "ERROR: Directory doesn't exist: $nemo_dir"
            launch_and_focus ""
        fi
        ;;
esac