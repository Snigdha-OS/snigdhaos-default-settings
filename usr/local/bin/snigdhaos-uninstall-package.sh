#!/bin/bash

# Author        : Eshan Roy
# Author URL    : https://eshanized.github.io/

set -e  # Exit immediately if a command exits with a non-zero status

# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RESET="\033[0m"

# Function to display error message and exit
error_handler() {
    echo -e "\n${RED}🚨 An error occurred during the uninstallation process.${RESET}"
    echo -e "${RED}Error on line $1. Please check your system and try again.${RESET}"
    exit 1
}

# Trap errors and call error_handler
trap 'error_handler $LINENO' ERR

# Function to display help message
show_help() {
    echo -e "${BLUE}Usage: ${RESET}$0 <package_name>"
    echo -e ""
    echo -e "${GREEN}This script will uninstall the specified package, remove its cache, and clean up orphaned packages.${RESET}"
    echo -e ""
    echo -e "${YELLOW}Options:${RESET}"
    echo -e "  ${GREEN}-h, --help${RESET}          Show this help message."
    echo -e "  ${GREEN}<package_name>${RESET}       The package to uninstall."
    echo -e ""
    echo -e "${YELLOW}Example usage:${RESET}"
    echo -e "  $0 firefox                # Uninstalls the Firefox package and its cache."
    echo -e "  $0 -h                     # Displays this help message."
}

# Parse command line options
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Ensure the script is run as root for certain actions
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run this script as root or with sudo.${RESET}"
    exit 1
fi

# Check if a package name is provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ No package specified.${RESET}"
    echo -e "Usage: $0 <package_name>"
    exit 1
fi

PACKAGE=$1

# Confirm with the user
echo -e "${YELLOW}⚠️ WARNING: This script will uninstall the specified package and remove its cache.${RESET}"
read -p "$(echo -e "${BLUE}Are you sure you want to uninstall $PACKAGE and remove its cache? [y/N]: ${RESET}")" CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo -e "${RED}❌ Operation cancelled.${RESET}"
    exit 0
fi

# Uninstall the package and its dependencies
echo -e "${BLUE}📦 Uninstalling $PACKAGE...${RESET}"
sudo pacman -Rns $PACKAGE --noconfirm || { echo -e "${RED}❌ Failed to uninstall $PACKAGE.${RESET}"; exit 1; }

# Remove the package's cache
echo -e "${BLUE}🗑️ Removing cache for $PACKAGE...${RESET}"
sudo pacman -Sc --noconfirm || echo -e "${YELLOW}❗ Cache removal skipped.${RESET}"

# Clean up orphaned packages
echo -e "${BLUE}🧹 Cleaning up orphaned packages...${RESET}"
sudo pacman -Rns $(pacman -Qtdq) --noconfirm || echo -e "${YELLOW}No orphaned packages to remove.${RESET}"

echo -e "\n${GREEN}✅ Package $PACKAGE successfully uninstalled!${RESET}"
exit 0
