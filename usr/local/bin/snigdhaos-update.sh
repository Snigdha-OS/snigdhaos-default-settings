#!/bin/bash

# Author        : Eshan Roy
# Author URL    : https://eshanized.github.io/

# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RESET="\033[0m"

# Function to display error message and exit
error_handler() {
    echo -e "\n${RED}🚨 An error occurred during the update process.${RESET}"
    echo -e "${RED}Error on line $1. Please check your system and try again.${RESET}"
    exit 1
}

# Trap errors and call error_handler
trap 'error_handler $LINENO' ERR

# Function to display help message
show_help() {
    echo -e "${BLUE}Usage: ${RESET}$0"
    echo -e ""
    echo -e "${GREEN}This script will update the package database, upgrade all installed packages, and clean up orphaned packages.${RESET}"
    echo -e ""
    echo -e "${YELLOW}Options:${RESET}"
    echo -e "  ${GREEN}-h, --help${RESET}          Show this help message."
    echo -e ""
    echo -e "${YELLOW}Example usage:${RESET}"
    echo -e "  $0                         # Updates the system and removes orphaned packages."
    echo -e "  $0 -h                      # Displays this help message."
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

# Warning before starting
echo -e "${YELLOW}⚠️ WARNING: This script will update your system, upgrade installed packages, and clean up orphaned packages.${RESET}"
read -p "$(echo -e "${BLUE}Are you sure you want to proceed? [y/N]: ${RESET}")" CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo -e "${RED}❌ Operation cancelled.${RESET}"
    exit 0
fi

# Update the package database and upgrade packages
echo -e "${BLUE}🔄 Updating the package database...${RESET}"
sudo pacman -Sy || { echo -e "${RED}❌ Failed to update the package database.${RESET}"; exit 1; }

echo -e "${BLUE}📦 Upgrading installed packages...${RESET}"
sudo pacman -Su --noconfirm || { echo -e "${RED}❌ Failed to upgrade packages.${RESET}"; exit 1; }

# Clean up orphaned packages
echo -e "${BLUE}🧹 Cleaning up orphaned packages...${RESET}"
sudo pacman -Rns $(pacman -Qtdq) --noconfirm || echo -e "${YELLOW}No orphaned packages to remove.${RESET}"

echo -e "\n${GREEN}✅ System successfully updated!${RESET}"
exit 0
