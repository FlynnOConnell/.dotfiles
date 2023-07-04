#!/bin/bash

# Check if the tpm directory exists
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    # If not, clone the tpm repository
    echo "Cloning tmux plugin manager (tpm)..."
    git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
else
    echo "tmux plugin manager (tpm) already exists. Skipping clone."
fi

