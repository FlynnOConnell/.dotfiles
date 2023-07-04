#!/bin/bash

# Check if the kitty is installed
if ! command -v kitty &> /dev/null; then
    echo "kitty terminal emulator is not installed. Installing..."
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
else
    echo "kitty terminal emulator is already installed. Skipping installation."
fi

