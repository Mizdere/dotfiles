#!/bin/bash

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILENAME="Screenshot_$(date +%Y%m%d_%H%M%S).png"

# Freeze screen using hyprpicker, then let slurp drag
hyprpicker -r -z &
PID=$!

# Let the overlay appear
sleep 0.2

# Use slurp to select area
REGION=$(slurp)

# Kill hyprpicker overlay
kill "$PID" 2>/dev/null

# If user selected something, capture it and copy to clipboard only
if [ -n "$REGION" ]; then
    grim -g "$REGION" - | wl-copy
fi
