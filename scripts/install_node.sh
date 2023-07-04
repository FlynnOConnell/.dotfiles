#!/bin/bash

# Check if the npm is installed
if ! command -v npm &> /dev/null; then
    echo "npm is not installed. Installing..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "npm is already installed. Skipping installation."
fi

