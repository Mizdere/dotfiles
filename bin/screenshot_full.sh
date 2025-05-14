#!/bin/bash
DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILENAME="Screenshot_$(date +%Y%m%d_%H%M%S).png"
grim "$DIR/$FILENAME"
