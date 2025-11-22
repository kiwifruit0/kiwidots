#!/bin/bash

set -euo pipefail

cd ~/dotfiles || exit 1

echo "Stowing home config..."
stow -R -v config

echo "Stowing system files..."
sudo stow -R -v -t / system

echo "All packages stowed successfully!"

