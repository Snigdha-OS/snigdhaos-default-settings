#!/bin/bash

# Author        : Eshan Roy
# Author URL    : https://eshanized.github.io/

# Colors for formatting output in terminal
RED="\033[1;31m"        # Red color for errors
GREEN="\033[1;32m"      # Green color for success messages
YELLOW="\033[1;33m"     # Yellow color for warnings
BLUE="\033[1;34m"       # Blue color for info messages
RESET="\033[0m"         # Reset color to default

# Log File path to save script output
LOG_FILE="/var/log/snigdha_update_script.log"

# Function to display error message and exit
error_handler() {
    echo -e "\n${RED}🚨 An error occurred during the update process.${RESET}"  # Print error message in red
    echo -e "${RED}Error on line $1. Please check your system and try again.${RESET}"  # Indicate the line number where error occurred
    echo -e "$(date) - Error on line $1" >> $LOG_FILE  # Log error with timestamp
    exit 1  # Exit the script with error status
}

# Trap errors and call error_handler when an error occurs
trap 'error_handler $LINENO' ERR

# Function to display help message
show_help() {
    # Display general usage of the script
    echo -e "${BLUE}Usage: ${RESET}$0 [options]"
    echo -e ""
    echo -e "${GREEN}This script will update the package database, upgrade all installed packages, and clean up orphaned packages.${RESET}"
    echo -e ""
    # Show available options for the script
    echo -e "${YELLOW}Options:${RESET}"
    echo -e "  ${GREEN}-h, --help${RESET}          Show this help message."
    echo -e "  ${GREEN}-v, --verbose${RESET}       Enable verbose output."
    echo -e "  ${GREEN}-d, --dry-run${RESET}       Show what would be done without making changes."
    echo -e "  ${GREEN}-b, --backup${RESET}        Backup important configuration files before updating."
    echo -e ""
    # Provide usage examples for the user
    echo -e "${YELLOW}Example usage:${RESET}"
    echo -e "  $0                         # Updates the system and removes orphaned packages."
    echo -e "  $0 -v                      # Run in verbose mode."
    echo -e "  $0 -d                      # Dry run (preview only)."
    echo -e "  $0 -b                      # Backup configuration files before updating."
}

# Parse command line options for verbose, dry-run, and backup flags
VERBOSE=false  # Default to false, verbose output is off
DRY_RUN=false  # Default to false, dry-run mode is off
BACKUP=false   # Default to false, backup is not done by default

while [[ "$1" != "" ]]; do  # Loop through each command-line argument
    case $1 in
        -h|--help) show_help; exit 0 ;;        # If -h or --help is passed, show help and exit
        -v|--verbose) VERBOSE=true ;;          # If -v or --verbose is passed, enable verbose mode
        -d|--dry-run) DRY_RUN=true ;;          # If -d or --dry-run is passed, enable dry-run mode
        -b|--backup) BACKUP=true ;;            # If -b or --backup is passed, enable backup option
        *) echo -e "${RED}❌ Invalid option: $1${RESET}"; show_help; exit 1 ;;  # Handle invalid options
    esac
    shift  # Move to the next argument
done

# Ensure the script is run as root for certain actions
if [ "$EUID" -ne 0 ]; then  # Check if the script is being run by root user
    echo -e "${RED}❌ Please run this script as root or with sudo.${RESET}"  # Print error if not root
    exit 1  # Exit the script
fi

# Warning message before proceeding with the update
echo -e "${YELLOW}⚠️ WARNING: This script will update your system, upgrade installed packages, and clean up orphaned packages.${RESET}"
if $BACKUP; then  # If the backup option is enabled
    echo -e "${YELLOW}⚠️ You have chosen to backup important configuration files.${RESET}"
    read -p "$(echo -e "${BLUE}Are you sure you want to proceed? [y/N]: ${RESET}")" CONFIRM  # Ask for confirmation
else
    read -p "$(echo -e "${BLUE}Are you sure you want to proceed? [y/N]: ${RESET}")" CONFIRM  # Normal confirmation prompt
fi
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then  # Check if user confirmed
    echo -e "${RED}❌ Operation cancelled.${RESET}"  # Print cancellation message
    exit 0  # Exit the script
fi

# Backup important configuration files (optional)
backup_config_files() {
    echo -e "${BLUE}📦 Backing up important configuration files...${RESET}"  # Inform about backup
    BACKUP_DIR="/home/$USER/important_configs"  # Directory to store backups
    mkdir -p $BACKUP_DIR  # Create backup directory if it doesn't exist

    # List of important config files to back up
    CONFIG_FILES=(
        "/etc/pacman.conf"
        "/etc/makepkg.conf"
        "/etc/sudoers"
        "/etc/systemd/system"
        "$HOME/.bashrc"
        "$HOME/.zshrc"
    )

    for FILE in "${CONFIG_FILES[@]}"; do  # Loop through each config file
        if [ -e "$FILE" ]; then  # Check if the file exists
            cp -r "$FILE" "$BACKUP_DIR" || { echo -e "${RED}❌ Failed to back up $FILE.${RESET}"; exit 1; }  # Copy the file to backup
            echo -e "${GREEN}✅ Backed up $FILE${RESET}"  # Inform the user the file was backed up
        else
            echo -e "${YELLOW}⚠️ Skipping $FILE (not found).${RESET}"  # If the file is not found, skip it
        fi
    done
}

# Log the start of the script
echo -e "$(date) - Starting update process" >> $LOG_FILE  # Log the start with timestamp

# Update the package database and upgrade packages
echo -e "${BLUE}🔄 Updating the package database...${RESET}"
if $VERBOSE; then  # If verbose mode is enabled
    sudo pacman -Sy --verbose || error_handler $LINENO  # Run with verbose output
else
    sudo pacman -Sy || error_handler $LINENO  # Run normally
fi

echo -e "${BLUE}📦 Upgrading installed packages...${RESET}"
if $DRY_RUN; then  # If dry-run mode is enabled
    echo -e "${YELLOW}⚠️ Dry run mode: The following commands would be executed but won't make changes.${RESET}"
    echo -e "  sudo pacman -Su --noconfirm"  # Show the dry-run commands
else
    if $VERBOSE; then  # If verbose mode is enabled
        sudo pacman -Su --noconfirm --verbose || error_handler $LINENO  # Upgrade with verbose
    else
        sudo pacman -Su --noconfirm || error_handler $LINENO  # Upgrade normally
    fi
fi

# Clean up orphaned packages
echo -e "${BLUE}🧹 Cleaning up orphaned packages...${RESET}"
if $DRY_RUN; then  # If dry-run mode is enabled
    orphaned_packages=$(pacman -Qtdq)  # List orphaned packages
    if [ -z "$orphaned_packages" ]; then  # If no orphaned packages
        echo -e "${YELLOW}No orphaned packages to remove.${RESET}"  # Inform the user
    else  # If orphaned packages exist
        echo -e "${YELLOW}The following orphaned packages would be removed:${RESET} $orphaned_packages"
    fi
else  # If dry-run mode is not enabled
    sudo pacman -Rns $(pacman -Qtdq) --noconfirm || echo -e "${YELLOW}No orphaned packages to remove.${RESET}"  # Remove orphaned packages
fi

# Log successful completion
echo -e "$(date) - System successfully updated." >> $LOG_FILE  # Log the successful completion

# Final success message
echo -e "\n${GREEN}✅ System successfully updated!${RESET}"  # Print success message
exit 0  # Exit the script
