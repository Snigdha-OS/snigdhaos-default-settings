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
    echo -e "\n${RED}🚨 An error occurred during the cleanup process.${RESET}"
    echo -e "${RED}Error on line $1. Please check your system and try again.${RESET}"
    exit 1
}

# Trap errors and call error_handler
trap 'error_handler $LINENO' ERR

# Ensure the script is run as root for certain actions
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run this script as root or with sudo.${RESET}"
    exit 1
fi

echo -e "${YELLOW}⚠️ WARNING: This script will permanently delete unnecessary files, logs, and caches to free up disk space.${RESET}"
echo -e "${BLUE}👉 The following will be cleaned:${RESET}"
echo -e "${GREEN}   - Package cache${RESET}"
echo -e "${GREEN}   - Crash reports${RESET}"
echo -e "${GREEN}   - Application logs${RESET}"
echo -e "${GREEN}   - Application caches${RESET}"
echo -e "${GREEN}   - Trash${RESET}"
read -p "$(echo -e "${YELLOW}❓ Are you sure you want to proceed? [y/N]: ${RESET}")" CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo -e "${RED}❌ Cleanup operation cancelled.${RESET}"
    exit 0
fi

# Function to calculate space freed
calculate_space_freed() {
    local before_size
    local after_size

    before_size=$(du -sh / | awk '{print $1}')
    
    # Running cleanup functions
    clean_package_cache
    clean_crash_reports
    clean_application_logs
    clean_application_caches
    clean_trash

    after_size=$(du -sh / | awk '{print $1}')

    echo -e "${GREEN}Space freed: $before_size -> $after_size${RESET}"
}

echo -e "${BLUE}🧹 Starting cleanup process...${RESET}"

# Function to clean package cache
clean_package_cache() {
    echo -e "${YELLOW}⚠️ Deleting package cache (this will remove old cached packages and free up disk space)...${RESET}"
    sudo pacman -Sc --noconfirm || { echo -e "${RED}❌ Failed to clean package cache.${RESET}"; exit 1; }
    echo -e "${GREEN}✅ Package cache cleaned.${RESET}"
}

# Function to clean crash reports
clean_crash_reports() {
    echo -e "${YELLOW}⚠️ Deleting crash reports (this will remove saved system crash data)...${RESET}"
    CRASH_DIR="/var/lib/systemd/coredump"
    if [ -d "$CRASH_DIR" ]; then
        sudo rm -rf "$CRASH_DIR"/* || { echo -e "${RED}❌ Failed to clean crash reports.${RESET}"; exit 1; }
        echo -e "${GREEN}✅ Crash reports cleaned.${RESET}"
    else
        echo -e "${GREEN}✅ No crash reports found.${RESET}"
    fi
}

# Function to clean application logs
clean_application_logs() {
    echo -e "${YELLOW}⚠️ Truncating application logs (this will reset log files to 0 bytes)...${RESET}"
    LOG_DIR="/var/log"
    sudo find "$LOG_DIR" -type f -name "*.log" -exec truncate -s 0 {} \; || { echo -e "${RED}❌ Failed to clean application logs.${RESET}"; exit 1; }
    echo -e "${GREEN}✅ Application logs cleaned.${RESET}"
}

# Function to clean application caches
clean_application_caches() {
    echo -e "${YELLOW}⚠️ Deleting application caches (this will remove all cache files from user directories)...${RESET}"
    CACHE_DIR="/home/*/.cache"
    sudo rm -rf $CACHE_DIR/* || { echo -e "${RED}❌ Failed to clean application caches.${RESET}"; exit 1; }
    echo -e "${GREEN}✅ Application caches cleaned.${RESET}"
}

# Function to empty trash
clean_trash() {
    echo -e "${YELLOW}⚠️ Emptying trash (this will delete all items in the trash folders)...${RESET}"
    TRASH_DIR="/home/*/.local/share/Trash"
    sudo rm -rf $TRASH_DIR/* || { echo -e "${RED}❌ Failed to empty trash.${RESET}"; exit 1; }
    echo -e "${GREEN}✅ Trash emptied.${RESET}"
}

# Calculate space freed before and after cleanup
calculate_space_freed

echo -e "\n${GREEN}✅ Cleanup completed successfully!${RESET}"
exit 0
