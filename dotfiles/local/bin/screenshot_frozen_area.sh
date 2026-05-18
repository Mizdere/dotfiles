#!/bin/bash

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILENAME="Screenshot_$(date +%Y%m%d_%H%M%S).png"

# Freeze screen using hyprpicker, then let slurp drag
hyprpicker -r -z &
PID=$!

# Let the overlay appear
sleep 0.2

# Use slurp to select area and show live dimensions while dragging
REGION=$(slurp -d -c ffffffff -b 00000066)

# Kill hyprpicker overlay
kill "$PID" 2>/dev/null

# If user selected something, capture it to file or copy to clipboard.
if [ -n "$REGION" ]; then
    if [ "$1" = "save" ]; then
        grim -g "$REGION" "$DIR/$FILENAME"
    else
        grim -g "$REGION" - | wl-copy
    fi
fi
