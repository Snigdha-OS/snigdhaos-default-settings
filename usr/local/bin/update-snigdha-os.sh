#!/bin/bash

# Author        : Eshan Roy
# Author URL    : https://eshanized.github.io/

# Shell script to update all Snigdha OS packages with error handling

set -e  # Exit immediately if a command exits with a non-zero status

# Function to display error message and exit
error_handler() {
    echo -e "\n🚨 An error occurred during the update process."
    echo "Error on line $1. Please check your system and try again."
    exit 1
}

# Trap errors and call error_handler
trap 'error_handler $LINENO' ERR

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run this script as root or with sudo."
    exit 1
fi

# Update the package database and upgrade packages
echo "🔄 Updating the package database..."
sudo pacman -Sy || { echo "❌ Failed to update the package database."; exit 1; }

echo "📦 Upgrading installed packages..."
sudo pacman -Su --noconfirm || { echo "❌ Failed to upgrade packages."; exit 1; }

# Clean up orphaned packages
echo "🧹 Cleaning up orphaned packages..."
sudo pacman -Rns $(pacman -Qtdq) --noconfirm || echo "No orphaned packages to remove."

echo -e "\n✅ System successfully updated!"
exit 0
