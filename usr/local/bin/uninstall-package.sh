#!/bin/bash

# Author        : Eshan Roy
# Author URL    : https://eshanized.github.io/

set -e  # Exit immediately if a command exits with a non-zero status

# Function to display error message and exit
error_handler() {
    echo -e "\n🚨 An error occurred during the uninstallation process."
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

# Check if a package name is provided
if [ -z "$1" ]; then
    echo "❌ No package specified."
    echo "Usage: $0 <package_name>"
    exit 1
fi

PACKAGE=$1

# Confirm with the user
read -p "Are you sure you want to uninstall $PACKAGE and remove its cache? [y/N]: " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "❌ Operation cancelled."
    exit 0
fi

# Uninstall the package and its dependencies
echo "📦 Uninstalling $PACKAGE..."
sudo pacman -Rns $PACKAGE --noconfirm || { echo "❌ Failed to uninstall $PACKAGE."; exit 1; }

# Remove the package's cache
echo "🗑️ Removing cache for $PACKAGE..."
sudo pacman -Sc --noconfirm || echo "❗ Cache removal skipped."

# Clean up orphaned packages
echo "🧹 Cleaning up orphaned packages..."
sudo pacman -Rns $(pacman -Qtdq) --noconfirm || echo "No orphaned packages to remove."

echo -e "\n✅ Package $PACKAGE successfully uninstalled!"
exit 0
