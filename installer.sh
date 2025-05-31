#!/bin/bash

#    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
#    ░                                              ░
#    ░    ███████╗██╗   ██╗ ██████╗ ██╗███████╗     ░
#    ░    ██╔════╝██║   ██║██╔════╝ ██║██╔════╝     ░
#    ░    █████╗  ██║   ██║██║  ███╗██║███████╗     ░
#    ░    ██╔══╝  ██║   ██║██║   ██║██║╚════██║     ░
#    ░    ██║     ╚██████╔╝╚██████╔╝██║███████║     ░
#    ░    ╚═╝      ╚═════╝  ╚═════╝ ╚═╝╚══════╝     ░
#    ░                                              ░
#    ░  Fast Universal Gentoo Installation Script   ░
#    ░    Created by Realist (c) 2023-2025 v1.7     ░
#    ░                                              ░
#    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

# Fast Universal Gentoo Installation Script (c) 2023 - 2025 v 1.7
# with interactive setup, zstd compression on F2FS and ZRAM swapfile

# This script is designed to be run from a live environment CD or USB
# It will install Gentoo Linux on the specified target partition

# FUGIS installer home repo: https://github.com/lotrando/fugis-gentoo-installer
# make custom fork and change GENTOO_INSTALLER_URL with URL to your fork

GENTOO_INSTALLER_URL=https://raw.githubusercontent.com/lotrando/fugis-gentoo-installer/refs/heads/main

# Optional parameters for create and save config to gist
# Your Gist token (optional) insert your token for create gist with fugis.conf
GITHUB_TOKEN=""
# Optional parameters for load config from gist
# Your Gist ID (optional) insert your gist id for download fugis.conf
# Your Gist ID for updates (leave empty to create new)
GITHUB_GIST_ID=""

# Load config fom file if exists. I not exists prompt for load config from Gist and gist ID
load_config() {
    if [[ -f "$GENTOO_CONFIG_FILE" ]]; then
        source "$GENTOO_CONFIG_FILE"
        log_info "✓ Configuration loaded from $GENTOO_CONFIG_FILE"
    else
        echo ""
        read -n1 -p "$(echo -e "${YELLOW}Download config from Gist? (y/n): ${RESET}")" download_choice
        echo ""
        if [[ "$download_choice" == "y" || "$download_choice" == "Y" ]]; then
            download_config_from_gist
            if [[ -f "$GENTOO_CONFIG_FILE" ]]; then
                source "$GENTOO_CONFIG_FILE"
            fi
        fi
    fi
}

# Upload or update config to Gist
upload_config_to_gist() {
    # Check for gist token
    if [[ -z "$GITHUB_TOKEN" ]]; then
        log_warning "GitHub token not set. Skipping online config upload."
        return 1
    fi

    # Check for config file
    if [[ ! -f "$GENTOO_CONFIG_FILE" ]]; then
        log_error "Configuration file not found: $GENTOO_CONFIG_FILE"
        return 1
    fi

    # Prepare content
    local config_content=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(echo "$line" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
        if [[ -n "$config_content" ]]; then
            config_content="${config_content}\\n${line}"
        else
            config_content="$line"
        fi
    done < "$GENTOO_CONFIG_FILE"

    if [[ -n "$GITHUB_GIST_ID" ]]; then
        # Update
        update_existing_gist "$config_content"
    else
        # Create
        create_new_gist "$config_content"
    fi
}

# Create new Gist
create_new_gist() {
    local config_content="$1"

    log_info "✓ Creating new Gist..."

    local json_payload=$(cat << EOF
{
    "description": "FUGIS Configuration - $(date '+%Y-%m-%d %H:%M:%S')",
    "public": false,
    "files": {
        "fugis.conf": {
            "content": "$config_content"
        }
    }
}
EOF
)

    local response=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        https://api.github.com/gists)

    local http_code=$(echo "$response" | tail -n1)
    local json_response=$(echo "$response" | head -n -1)

    if [[ "$http_code" != "201" ]]; then
        log_error "GitHub API returned HTTP $http_code"
        local error_msg=$(echo "$json_response" | sed -n 's/.*"message"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
        if [[ -n "$error_msg" ]]; then
            log_error "GitHub API error: $error_msg"
        fi
        return 1
    fi

    local gist_url=$(echo "$json_response" | sed -n 's/.*"html_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
    local gist_id=$(echo "$json_response" | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)

    if [[ -n "$gist_url" && -n "$gist_id" ]]; then
        echo -e "${GREEN}✓ New Gist created successfully!${RESET}"
        echo -e "${CYAN}Gist URL: $gist_url${RESET}"
        echo -e "${CYAN}Gist ID: $gist_id${RESET}"
        echo -e "${YELLOW}Save this Gist ID for future updates: $gist_id${RESET}"

        log_info "✓ New Gist created: $gist_url"
        return 0
    else
        log_error "Failed to parse new Gist response"
        return 1
    fi
}

# Update existing Gist
update_existing_gist() {
    local config_content="$1"

    log_info "✓ Updating existing Gist ID: $GITHUB_GIST_ID"

    local json_payload=$(cat << EOF
{
    "description": "FUGIS Configuration - Updated $(date '+%Y-%m-%d %H:%M:%S')",
    "files": {
        "fugis.conf": {
            "content": "$config_content"
        }
    }
}
EOF
)

    local response=$(curl -s -w "\n%{http_code}" -X PATCH \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        "https://api.github.com/gists/$GITHUB_GIST_ID")

    local http_code=$(echo "$response" | tail -n1)
    local json_response=$(echo "$response" | head -n -1)

    if [[ "$http_code" != "200" ]]; then
        log_error "Failed to update Gist. HTTP $http_code"
        local error_msg=$(echo "$json_response" | sed -n 's/.*"message"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
        if [[ -n "$error_msg" ]]; then
            log_error "GitHub API error: $error_msg"
        fi

        # If update fails, offer to create new Gist
        echo ""
        read -n1 -p "$(echo -e "${YELLOW}Update failed. Create new Gist instead? (y/n): ${RESET}")" create_new
        echo ""
        if [[ "$create_new" == "y" || "$create_new" == "Y" ]]; then
            create_new_gist "$config_content"
        fi
        return 1
    fi

    local gist_url=$(echo "$json_response" | sed -n 's/.*"html_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)

    if [[ -n "$gist_url" ]]; then
       log_info "✓ Gist updated successfully!"
        echo -e "${CYAN}Gist URL: $gist_url${RESET}"
        echo -e "${CYAN}Gist ID: $GITHUB_GIST_ID${RESET}"

        log_info "✓ Gist updated: $gist_url"
        return 0
    else
        log_error "Failed to parse update response"
        return 1
    fi
}

# Load config from Gist
download_config_from_gist() {
    local gist_id="${1:-$GITHUB_GIST_ID}"

    if [[ -z "$gist_id" ]]; then
        read -p "$(echo -e "${BLUE}Enter Gist ID:${RESET} ")" gist_id
    fi

    if [[ -z "$gist_id" ]]; then
        log_error "Gist ID is required"
        return 1
    fi

    log_info "✓ Downloading configuration from Gist ID: $gist_id"

    # Try raw URL first (simpler and more reliable)
    local raw_url="https://gist.githubusercontent.com/raw/$gist_id/fugis.conf"

    if curl -s -f "$raw_url" -o "$GENTOO_CONFIG_FILE"; then
        log_info "✓ Configuration downloaded successfully"
        return 0
    else
        log_error "Failed to download from raw URL: $raw_url"
        return 1
    fi
}

SWAP_SIZE="${SWAP_SIZE:-2048}"
SWAPFILE_SIZE="${SWAPFILE_SIZE:-1024}"
SWAPFILE_PATH="${SWAPFILE_PATH:-/swapfile}"

# Configure SWAP partition
configure_swap_partition() {
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')

    # Doporučená velikost podle RAM
    if [ "$TOTAL_RAM" -le 2048 ]; then
        RECOMMENDED_SWAP=$((TOTAL_RAM * 2))
    elif [ "$TOTAL_RAM" -le 8192 ]; then
        RECOMMENDED_SWAP=$TOTAL_RAM
    else
        RECOMMENDED_SWAP=8192
    fi

    echo ""
    echo -e "${CYAN}Recommended swap partition size: ${RECOMMENDED_SWAP} MB${RESET}"

    while true; do
        read -p "Swap partition size in MB [$(echo -e "${GREEN}${SWAP_SIZE:-$RECOMMENDED_SWAP}${RESET}")]: " input
        SWAP_SIZE=${input:-${SWAP_SIZE:-$RECOMMENDED_SWAP}}
        if [[ "$SWAP_SIZE" =~ ^[0-9]+$ ]] && [ "$SWAP_SIZE" -ge 512 ]; then
            break
        else
            log_error "Swap size must be a number >= 512 MB"
        fi
    done
}

# Configure SWAP file
configure_swap_file() {
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
    RECOMMENDED_SWAP=$((TOTAL_RAM / 2))

    echo ""
    while true; do
        read -p "Swap file size in MB [$(echo -e "${GREEN}${SWAPFILE_SIZE:-$RECOMMENDED_SWAP}${RESET}")]: " input
        SWAPFILE_SIZE=${input:-${SWAPFILE_SIZE:-$RECOMMENDED_SWAP}}
        if [[ "$SWAPFILE_SIZE" =~ ^[0-9]+$ ]] && [ "$SWAPFILE_SIZE" -ge 512 ]; then
            break
        else
            log_error "The swap file size must be a number >= 512 MB"
        fi
    done

    read -p "Path to the swap file [$(echo -e "${GREEN}${SWAPFILE_PATH:-/swapfile}${RESET}")]: " input
    SWAPFILE_PATH=${input:-${SWAPFILE_PATH:-/swapfile}}
}

# Save config function
save_config() {
    cat > "$GENTOO_CONFIG_FILE" <<EOF
UEFI_DISK_SIZE="$UEFI_DISK_SIZE"
GENTOO_USER="$GENTOO_USER"
GENTOO_USER_PASSWORD="$GENTOO_USER_PASSWORD"
GENTOO_ROOT_PASSWORD="$GENTOO_ROOT_PASSWORD"
GENTOO_HOSTNAME="$GENTOO_HOSTNAME"
GENTOO_DOMAINNAME="$GENTOO_DOMAINNAME"
GRUB_GFX_MODE="$GRUB_GFX_MODE"
GENTOO_ZONEINFO="$GENTOO_ZONEINFO"
GENTOO_KEYMAP="$GENTOO_KEYMAP"
EOF

    log_info "✓ Configuration saved to $GENTOO_CONFIG_FILE"

    # If GitHub token is set, offer upload/update
    if [[ -n "$GITHUB_TOKEN" ]]; then
        echo ""
        if [[ -n "$GITHUB_GIST_ID" ]]; then
            read -n1 -p "$(echo -e "${YELLOW}Update existing Gist (ID: $GITHUB_GIST_ID)? (y/n): ${RESET}")" upload_choice
        else
            read -n1 -p "$(echo -e "${YELLOW}Upload config to new GitHub Gist? (y/n): ${RESET}")" upload_choice
        fi
        echo ""
        if [[ "$upload_choice" == "y" || "$upload_choice" == "Y" ]]; then
            upload_config_to_gist
        fi
    fi
}

# Important settings - do not change
GENTOO_CONFIG_FILE="fugis.conf"
GENTOO_LOG_FILE="fugis.log"
GENTOO_CONSOLEFONT=ter-v16b

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
LIGHT_YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_MAGENTA='\033[1;35m'
LIGHT_CYAN='\033[1;36m'
UNDERLINE='\033[4m'
RESET='\033[0m'

# Logging functions

# Initialize clean log file
echo "--- FUGIS Installation Log ---" > "$GENTOO_LOG_FILE"

trap 'handle_error $LINENO' ERR
set -e
trap cleanup EXIT

# Cleanup function
cleanup() {
    log_info "✓ Cleaning up..."
    umount -R /mnt/gentoo 2>/dev/null || true
}

# Function to strip ANSI color codes
strip_colors() {
    sed 's/\x1b\[[0-9;]*m//g'
}

# Logging functions info
log_info() {
    local message="[INFO] $1"
    echo -e "${GREEN}${message}${RESET}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') $message" >> "$GENTOO_LOG_FILE"
}

# Logging functions err
log_error() {
    local message="[ERROR] $1"
    echo -e "${RED}${message}${RESET}" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S') $message" >> "$GENTOO_LOG_FILE"
}

# Logging functions warning
log_warning() {
    local message="[WARNING] $1"
    echo -e "${YELLOW}${message}${RESET}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') $message" >> "$GENTOO_LOG_FILE"
}

# Error handling
handle_error() {
    log_error "Script failed at line $1"
    cleanup
    exit 1
}

# Validation functions
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -ra ADDR <<< "$ip"
        for i in "${ADDR[@]}"; do
            if [[ $i -gt 255 || $i -lt 0 ]]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# Netmask to CDIR convert
netmask_to_cidr() {
    local netmask="$1"
    local cidr=0

    IFS='.' read -r i1 i2 i3 i4 <<< "$netmask"

    for octet in $i1 $i2 $i3 $i4; do
        case $octet in
            255) cidr=$((cidr + 8)) ;;
            254) cidr=$((cidr + 7)) ;;
            252) cidr=$((cidr + 6)) ;;
            248) cidr=$((cidr + 5)) ;;
            240) cidr=$((cidr + 4)) ;;
            224) cidr=$((cidr + 3)) ;;
            192) cidr=$((cidr + 2)) ;;
            128) cidr=$((cidr + 1)) ;;
            0) break ;;
            *) echo "24"; return ;;
        esac
    done

    echo "$cidr"
}

# Validation functions for hostname
validate_hostname() {
    local hostname=$1
    if [[ $hostname =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
        return 0
    fi
    return 1
}

# Validation functions for username
validate_username() {
    local username=$1
    if [[ $username =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]; then
        return 0
    fi
    return 1
}

# Installer header
HEADER_TEXT=(
    "               - F U G I S -               "
    " Fast Universal Gentoo Installation Script "
    "   Created by Realist (c) 2024-2025 v1.6   "
)

HEADER_WIDTH=0
for line in "${HEADER_TEXT[@]}"; do
    [ ${#line} -gt $HEADER_WIDTH ] && HEADER_WIDTH=${#line}
done
HEADER_WIDTH=$((HEADER_WIDTH + 2))

echo -e "${LIGHT_BLUE}╔$(printf '═%.0s' $(seq 1 $HEADER_WIDTH))╗${RESET}"
for line in "${HEADER_TEXT[@]}"; do
    printf "${LIGHT_BLUE}║ %-*s ║${RESET}\n" $((HEADER_WIDTH - 2)) "$line"
done
echo -e "${LIGHT_BLUE}╚$(printf '═%.0s' $(seq 1 $HEADER_WIDTH))╝${RESET}"

# Prerequisites check
log_info "✓ Checks prerequisites for installation"

# Check user must be root
if [ "$(id -u)" -ne 0 ]; then
    log_error "This script must be run as root!"
    exit 1
fi

# Check if the script is run from a live environment
if [ ! -d "/mnt/gentoo" ]; then
    log_error "Must be run from a live environment!"
    exit 1
fi

# Check required commands
for cmd in wget parted mkfs.fat mkfs.f2fs curl; do
    if ! command -v "$cmd" &> /dev/null; then
        log_error "Required command '$cmd' is not available"
        exit 1
    fi
done

# Check internet connectivity
if ! ping -c 1 8.8.8.8 &> /dev/null; then
    log_error "No internet connectivity detected"
    exit 1
fi

log_info "✓ All prerequisites met"

load_config

# Input settings function
input_settings() {
    # UEFI partition size
    echo ""
    echo -e "${LIGHT_MAGENTA}${UNDERLINE}UEFI partition size in MB:${RESET}"
    echo ""
    while true; do
        read -p "Enter UEFI partition size [$(echo -e "${GREEN}${UEFI_DISK_SIZE:-1024}${RESET}")]: " input
        UEFI_DISK_SIZE=${input:-${UEFI_DISK_SIZE:-1024}}
        if [[ "$UEFI_DISK_SIZE" =~ ^[0-9]+$ ]] && [ "$UEFI_DISK_SIZE" -ge 1024 ]; then
            break
        else
            log_error "UEFI partition size must be a number >= 1024 MB"
        fi
    done

    # Swap configuration
    echo ""
    echo -e "${LIGHT_MAGENTA}${UNDERLINE}SWAP config:${RESET}"
    echo ""
    echo -e "${YELLOW}1.${RESET} ${WHITE}SWAP File${RESET}"
    echo -e "${YELLOW}2.${RESET} ${WHITE}SWAP Partition${RESET}"
    echo -e "${YELLOW}3.${RESET} ${WHITE}SWAP Off${RESET}"

    while true; do
        echo ""
        read -p "$(echo -e "${BLUE}Choose SWAP type (1-3):${RESET} ")" swap_choice
        case "$swap_choice" in
            1)
                SWAP_TYPE="file"
                echo -e "You have chosen: ${GREEN}SWAP File${RESET}"
                configure_swap_file
                break
                ;;
            2)
                SWAP_TYPE="partition"
                echo -e "You have chosen: ${GREEN}SWAP Partition${RESET}"
                configure_swap_partition
                break
                ;;
            3)
                SWAP_TYPE="none"
                echo -e "You have chosen: ${GREEN}SWAP Off${RESET}"
                break
                ;;
            *)
                log_error "Invalid choice. Please try again."
                ;;
        esac
    done

    # User settings with validation
    echo ""
    echo -e "${LIGHT_MAGENTA}${UNDERLINE}Users and passwords:${RESET}"
    echo ""

    while true; do
        read -p "Enter username [$(echo -e "${GREEN}${GENTOO_USER:-user}${RESET}")]: " input
        GENTOO_USER=${input:-${GENTOO_USER:-user}}
        if validate_username "$GENTOO_USER"; then
            break
        else
            log_error "Invalid username format"
        fi
    done

    while true; do
        read -s -p "Enter user password [$(echo -e "${GREEN}${GENTOO_USER_PASSWORD:-toor}${RESET}")]: " input
        echo ""
        GENTOO_USER_PASSWORD=${input:-${GENTOO_USER_PASSWORD:-toor}}
        if [ ${#GENTOO_USER_PASSWORD} -ge 4 ]; then
            break
        else
            log_error "Password must be at least 4 characters long"
        fi
    done

    while true; do
        read -s -p "Enter root password [$(echo -e "${GREEN}${GENTOO_ROOT_PASSWORD:-toor}${RESET}")]: " input
        echo ""
        GENTOO_ROOT_PASSWORD=${input:-${GENTOO_ROOT_PASSWORD:-toor}}
        if [ ${#GENTOO_ROOT_PASSWORD} -ge 4 ]; then
            break
        else
            log_error "Password must be at least 4 characters long"
        fi
    done

    # Hostname and domain with validation
    echo ""
    echo -e "${LIGHT_MAGENTA}${UNDERLINE}Setup computer:${RESET}"
    echo ""

    while true; do
        read -p "Enter hostname [$(echo -e "${GREEN}${GENTOO_HOSTNAME:-gentoo}${RESET}")]: " input
        GENTOO_HOSTNAME=${input:-${GENTOO_HOSTNAME:-gentoo}}
        if validate_hostname "$GENTOO_HOSTNAME"; then
            break
        else
            log_error "Invalid hostname format"
        fi
    done

    read -p "Enter domain name [$(echo -e "${GREEN}${GENTOO_DOMAINNAME:-gentoo.dev}${RESET}")]: " input
    GENTOO_DOMAINNAME=${input:-${GENTOO_DOMAINNAME:-gentoo.dev}}

    # GRUB settings
    echo ""
    echo -e "${LIGHT_MAGENTA}${UNDERLINE}GRUB resolution:${RESET}"
    echo ""
    read -p "Enter GRUB gfx mode [$(echo -e "${GREEN}${GRUB_GFX_MODE:-1920x1080x32}${RESET}")]: " input
    GRUB_GFX_MODE=${input:-${GRUB_GFX_MODE:-1920x1080x32}}

    # Locale selection
    echo ""
    echo -e "${LIGHT_MAGENTA}${UNDERLINE}Setup locales:${RESET}"
    echo ""
    echo -e "${YELLOW}1.${RESET} ${WHITE}English (en_US.UTF-8)${RESET}"
    echo -e "${YELLOW}2.${RESET} ${WHITE}Czech (cs_CZ.UTF-8)${RESET}"

    while true; do
        read -p "$(echo -e "${BLUE}Select locale (1-2):${RESET} ")" locale_choice
        case "$locale_choice" in
            1) GENTOO_LOCALE="en_US.UTF-8"; break ;;
            2) GENTOO_LOCALE="cs_CZ.UTF-8"; break ;;
            *) log_error "Invalid choice. Please try again." ;;
        esac
    done

    read -p "Enter keymap [$(echo -e "${GREEN}${GENTOO_KEYMAP:-us}${RESET}")]: " input
    GENTOO_KEYMAP=${input:-${GENTOO_KEYMAP:-us}}

    read -p "Enter timezone [$(echo -e "${GREEN}${GENTOO_ZONEINFO:-Europe/Prague}${RESET}")]: " input
    GENTOO_ZONEINFO=${input:-${GENTOO_ZONEINFO:-Europe/Prague}}


    # Disk selection
    DISKS=($(lsblk -d -n -o NAME | awk '{print "/dev/" $1}'))
    echo ""
    echo -e "${LIGHT_MAGENTA}${UNDERLINE}Detected disks:${RESET}"
    echo ""
    for i in "${!DISKS[@]}"; do
        echo -e "${YELLOW}$((i+1)).${RESET} ${WHITE}${DISKS[$i]}${RESET}"
    done

    while true; do
        echo ""
        read -p "$(echo -e "${BLUE}Select disk by number (1-${#DISKS[@]}):${RESET} ")" disk_choice
        if [[ "$disk_choice" =~ ^[1-9][0-9]*$ ]] && [ "$disk_choice" -le "${#DISKS[@]}" ]; then
            TARGET_DISK="${DISKS[$((disk_choice-1))]}"
            if [[ "$TARGET_DISK" == *"nvme"* ]]; then
                PART_SUFFIX="p"
                DISK_TYPE="NVMe"
            else
                PART_SUFFIX=""
                DISK_TYPE="SSD/SATA"
            fi
            TARGET_PART="${TARGET_DISK}${PART_SUFFIX}"
            echo -e "You selected: ${GREEN}${TARGET_DISK}${RESET} (${DISK_TYPE})"
            break
        else
            log_error "Invalid choice. Please try again."
        fi
    done

    # Network interface selection
    NET_INTERFACES=($(ls /sys/class/net | grep -v lo))
    echo ""
    echo -e "${LIGHT_MAGENTA}${UNDERLINE}Detected network interfaces:${RESET}"
    echo ""
    for i in "${!NET_INTERFACES[@]}"; do
        echo -e "${YELLOW}$((i+1)).${RESET} ${WHITE}${NET_INTERFACES[$i]}${RESET}"
    done

    while true; do
        echo ""
        read -p "$(echo -e "${BLUE}Select network interface by number (1-${#NET_INTERFACES[@]}):${RESET} ")" net_choice
        if [[ "$net_choice" =~ ^[1-9][0-9]*$ ]] && [ "$net_choice" -le "${#NET_INTERFACES[@]}" ]; then
            TARGET_LAN="${NET_INTERFACES[$((net_choice-1))]}"
            echo -e "You selected: ${GREEN}${TARGET_LAN}${RESET}"
            break
        else
            log_error "Invalid choice. Please try again."
        fi
    done

    # Network configuration
    echo ""
    echo -e "${CYAN}${UNDERLINE}Network configuration:${RESET}"
    echo -e "${YELLOW}1.${RESET} ${WHITE}DHCP (automatic)${RESET}"
    echo -e "${YELLOW}2.${RESET} ${WHITE}Static IP${RESET}"

    while true; do
        echo ""
        read -p "$(echo -e "${BLUE}Select network configuration (1-2):${RESET} ")" net_cfg
        if [[ "$net_cfg" == "1" ]]; then
            NET_MODE="dhcp"
            echo -e "You selected: ${GREEN}DHCP${RESET}"
            TARGET_IP=""
            TARGET_MASK=""
            TARGET_GATE=""
            TARGET_DNS=""
            break
        elif [[ "$net_cfg" == "2" ]]; then
            NET_MODE="static"
            echo -e "You selected: ${GREEN}Static IP${RESET}"

            # Static IP validation
            while true; do
                read -p "$(echo -e "${BLUE}Enter static IP address [${TARGET_IP:-192.168.0.20}]:${RESET} ")" input
                TARGET_IP=${input:-${TARGET_IP:-192.168.0.20}}
                if validate_ip "$TARGET_IP"; then
                    break
                else
                    log_error "Invalid IP address format"
                fi
            done

            while true; do
                read -p "$(echo -e "${BLUE}Enter netmask [${TARGET_MASK:-255.255.255.0}]:${RESET} ")" input
                TARGET_MASK=${input:-${TARGET_MASK:-255.255.255.0}}
                if validate_ip "$TARGET_MASK"; then
                    break
                else
                    log_error "Invalid netmask format"
                fi
            done

            while true; do
                read -p "$(echo -e "${BLUE}Enter gateway [${TARGET_GATE:-192.168.0.1}]:${RESET} ")" input
                TARGET_GATE=${input:-${TARGET_GATE:-192.168.0.1}}
                if validate_ip "$TARGET_GATE"; then
                    break
                else
                    log_error "Invalid gateway IP format"
                fi
            done

            read -p "$(echo -e "${BLUE}Enter DNS servers (space separated) [${TARGET_DNS:-8.8.8.8 8.8.4.4}]:${RESET} ")" input
            TARGET_DNS=${input:-${TARGET_DNS:-"8.8.8.8 8.8.4.4"}}
            break
        else
            log_error "Invalid choice. Please try again."
        fi
    done

}




# Main input setting loop
while true; do
    input_settings

    # Summary and confirmation
    echo ""
    echo -e "${LIGHT_GREEN}${UNDERLINE}Summary of your settings:${RESET}"
    echo ""
    echo -e "${CYAN}UEFI size:${RESET} ${UEFI_DISK_SIZE} MB"
    echo -e "${CYAN}Username:${RESET} ${GENTOO_USER}"
    echo -e "${CYAN}User password:${RESET} ${GENTOO_USER_PASSWORD}"
    echo -e "${CYAN}Root password:${RESET} ${GENTOO_ROOT_PASSWORD}"
    echo -e "${CYAN}Hostname:${RESET} ${GENTOO_HOSTNAME}"
    echo -e "${CYAN}Domain name:${RESET} ${GENTOO_DOMAINNAME}"
    echo -e "${CYAN}GRUB Resolution:${RESET} ${GRUB_GFX_MODE}"
    echo -e "${CYAN}Timezone:${RESET} ${GENTOO_ZONEINFO}"
    echo -e "${CYAN}Keymap:${RESET} ${GENTOO_KEYMAP}"
    echo -e "${CYAN}Target disk:${RESET} ${TARGET_DISK}"
    echo -e "${CYAN}Network interface:${RESET} ${TARGET_LAN}"
    echo -e "${CYAN}Network mode:${RESET} ${NET_MODE}"
    if [[ "$NET_MODE" == "static" ]]; then
        echo -e "${CYAN}Static IP:${RESET} ${TARGET_IP}"
        echo -e "${CYAN}Netmask:${RESET} ${TARGET_MASK}"
        echo -e "${CYAN}Gateway:${RESET} ${TARGET_GATE}"
        echo -e "${CYAN}DNS:${RESET} ${TARGET_DNS}"
    fi
    echo -e "${CYAN}Swap type:${RESET} ${SWAP_TYPE}"
    if [[ "$SWAP_TYPE" == "partition" ]]; then
        echo -e "${CYAN}Swap partition:${RESET} ${SWAP_SIZE} MB"
    elif [[ "$SWAP_TYPE" == "file" ]]; then
        echo -e "${CYAN}Swap file:${RESET} ${SWAPFILE_PATH} (${SWAPFILE_SIZE} MB)"
    fi
    echo ""
    echo -e "${RED}WARNING: Confirm will COMPLETELY WIPE the selected disk!${RESET}"
    echo ""
    read -n1 -p "$(echo -e "${YELLOW}Is everything set as you want? (y/n): ${RESET}")" confirm
    echo ""
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        save_config
        break
    else
        clear
        echo -e "${RED}You chose to review your settings. Please re-enter your configuration.${RESET}"
    fi
done

if [[ "$NET_MODE" == "static" ]]; then
    TARGET_CIDR=$(netmask_to_cidr "$TARGET_MASK")
else
    TARGET_CIDR="24"  # default for DHCP (not used but defined)
fi

# Installation starts here
log_info "✓ Starting installation process..."

# DISK SETUP with error handling
log_info "✓ Starting disk setup..."

create_disk_partitions() {
    log_info "✓ Creating partitions on ${TARGET_DISK}"

    if ! parted -s ${TARGET_DISK} mklabel gpt &>/dev/null; then
        log_error "Failed to create GPT partition table"
        exit 1
    fi

    if [[ "$SWAP_TYPE" == "partition" ]]; then
        # Tři oddíly: UEFI, SWAP, ROOT
        if ! parted -a optimal ${TARGET_DISK} << PARTED_END &>/dev/null
unit mib
mkpart primary fat32 1 ${UEFI_DISK_SIZE}
name 1 UEFI
set 1 bios_grub on
mkpart primary linux-swap ${UEFI_DISK_SIZE} $((UEFI_DISK_SIZE + SWAP_SIZE))
name 2 SWAP
mkpart primary $((UEFI_DISK_SIZE + SWAP_SIZE)) -1
name 3 ROOT
quit
PARTED_END
        then
            log_error "Failed to create partitions with swap"
            exit 1
        fi

        # Make SWAP
        log_info "✓ Creating swap partition"
        if ! mkswap -L SWAP ${TARGET_PART}2 &>/dev/null; then
            log_error "Failed to create swap partition"
            exit 1
        fi
        # Make ROOT
        ROOT_PARTITION="${TARGET_PART}3"
    else
        # Two partitions: UEFI, ROOT [no swap]
        if ! parted -a optimal ${TARGET_DISK} << PARTED_END &>/dev/null
unit mib
mkpart primary fat32 1 ${UEFI_DISK_SIZE}
name 1 UEFI
set 1 bios_grub on
mkpart primary ${UEFI_DISK_SIZE} -1
name 2 ROOT
quit
PARTED_END
        then
            log_error "Failed to create partitions"
            exit 1
        fi

        ROOT_PARTITION="${TARGET_PART}2"
    fi

    # Make filesystems
    log_info "✓ Creating filesystems"

    if ! mkfs.fat -n UEFI -F32 ${TARGET_PART}1 &>/dev/null; then
        log_error "Failed to create UEFI filesystem"
        exit 1
    fi

    if ! mkfs.f2fs -l ROOT -O extra_attr,inode_checksum,sb_checksum,compression -f ${ROOT_PARTITION} &>/dev/null; then
        log_error "Failed to create root filesystem"
        exit 1
    fi
}

# Funkce pro připojení souborových systémů
mount_filesystems() {
    log_info "✓ Mounting filesystems"

    if ! mkdir -p /mnt/gentoo; then
        log_error "Failed to create mount point"
        exit 1
    fi

    if ! mount -t f2fs ${ROOT_PARTITION} /mnt/gentoo -o compress_algorithm=zstd,compress_extension=*; then
        log_error "Failed to mount root partition"
        exit 1
    fi

    if ! chattr -R +c /mnt/gentoo; then
        log_warning "Failed to set compression attribute (non-critical)"
    fi

    if ! mkdir -p /mnt/gentoo/boot; then
        log_error "Failed to create boot directory"
        exit 1
    fi

    if ! mount ${TARGET_PART}1 /mnt/gentoo/boot; then
        log_error "Failed to mount boot partition"
        exit 1
    fi

    # Aktivace swap oddílu pokud existuje
    if [[ "$SWAP_TYPE" == "partition" ]]; then
        log_info "✓ Activating swap partition"
        swapon ${TARGET_PART}2
    fi
}

create_disk_partitions
mount_filesystems

cd /mnt/gentoo

# Stage 3 download with error handling
log_info "✓ Downloading latest stage3 tarball"

GENTOO_RELEASES_URL="https://mirror.dkm.cz/gentoo/releases"
STAGE3_PATH_URL="$GENTOO_RELEASES_URL/amd64/autobuilds/latest-stage3-amd64-openrc.txt"

if ! STAGE3_URL=$(curl -s "$STAGE3_PATH_URL" | grep -Eo '([0-9TZ]+/stage3-amd64-openrc-[0-9TZ]+\.tar\.xz)' | head -n1); then
    log_error "Failed to get stage3 URL"
    exit 1
fi

STAGE3_DOWNLOAD_URL="${GENTOO_RELEASES_URL}/amd64/autobuilds/${STAGE3_URL}"
STAGE3_FILENAME=$(basename $STAGE3_URL)

log_info "✓ Downloading: $STAGE3_FILENAME"

if ! wget -q "$STAGE3_DOWNLOAD_URL"; then
    log_error "Failed to download stage3 tarball"
    exit 1
fi

# Extract stage3 with error handling
log_info "✓ Extracting stage3: $STAGE3_FILENAME"

if ! tar xpf ${STAGE3_FILENAME} --xattrs-include='*.*' --numeric-owner; then
    log_error "Failed to extract stage3 tarball"
    exit 1
fi

# Setup system with error handling
mkdir -p /mnt/gentoo/var/db/repos/gentoo
mkdir -p /mnt/gentoo/etc/portage/repos.conf

if ! cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/; then
    log_error "Failed to copy repos.conf"
    exit 1
fi

if ! cp /etc/resolv.conf /mnt/gentoo/etc/; then
    log_error "Failed to copy resolv.conf"
    exit 1
fi

# Remove downloaded tarball
log_info "✓ Cleaning up downloaded tarball"
rm "$STAGE3_FILENAME"

log_info "✓ Mounting system filesystems"
mount -t proc none /mnt/gentoo/proc
mount -t sysfs none /mnt/gentoo/sys
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --rbind /run /mnt/gentoo/run
mount --make-rslave /mnt/gentoo/run
test -L /dev/shm && rm /dev/shm && mkdir /dev/shm
mount --types tmpfs --options nosuid,nodev,noexec shm /dev/shm
chmod 1777 /dev/shm

optimize_makeopts() {
    # Detect CPU makeopts
    GENTOO_MAKEOPTS="MAKEOPTS=\"-j$(nproc)\""
}

optimize_cpu_flags() {
    # Detect CPU flags
    GENTOO_CPUFLAGS=$(cpuid2cpuflags | sed 's/^CPU_FLAGS_X86: //')
}

log_info "✓ Optimize CPU Flags"
optimize_use_flags
optimize_makeopts

# Create improved chroot script
log_info "✓ Creating chroot installation script"
# Před vstupem do chroot vytvořit konfigurační soubor:
log_info "✓ Creating configuration for chroot"

cat > /mnt/gentoo/tmp/chroot_config << EOF
GENTOO_MAKEOPTS="$GENTOO_MAKEOPTS"
GENTOO_CPUFLAGS="$GENTOO_CPUFLAGS"
GENTOO_INSTALLER_URL="$GENTOO_INSTALLER_URL"
TARGET_PART="$TARGET_PART"
SWAP_TYPE="$SWAP_TYPE"
GENTOO_HOSTNAME="$GENTOO_HOSTNAME"
GENTOO_CONSOLEFONT="$GENTOO_CONSOLEFONT"
GENTOO_DOMAINNAME="$GENTOO_DOMAINNAME"
NET_MODE="$NET_MODE"
TARGET_LAN="$TARGET_LAN"
TARGET_IP="$TARGET_IP"
TARGET_CIDR="$TARGET_CIDR"
TARGET_GATE="$TARGET_GATE"
TARGET_DNS="$TARGET_DNS"
TARGET_MASK="$TARGET_MASK"
GENTOO_KEYMAP="$GENTOO_KEYMAP"
GENTOO_LOCALE="$GENTOO_LOCALE"
GENTOO_ZONEINFO="$GENTOO_ZONEINFO"
SWAPFILE_SIZE="$SWAPFILE_SIZE"
SWAPFILE_PATH="$SWAPFILE_PATH"
GRUB_GFX_MODE="$GRUB_GFX_MODE"
GENTOO_ROOT_PASSWORD="$GENTOO_ROOT_PASSWORD"
GENTOO_USER="$GENTOO_USER"
GENTOO_USER_PASSWORD="$GENTOO_USER_PASSWORD"
TARGET_DISK="$TARGET_DISK"
EOF

cat > /mnt/gentoo/root/gentoo-chroot.sh << 'CHROOT_SCRIPT_END'
#!/bin/bash

# Načtení konfigurace
source /tmp/chroot_config

emerge-webrsync

cd /etc/portage/
rm -f make.conf
rm -rf package.use
rm -rf package.accept_keywords
rm -rf package.mask

wget -q "${GENTOO_INSTALLER_URL}/make.conf"
wget -q "${GENTOO_INSTALLER_URL}/package.accept_keywords"
wget -q "${GENTOO_INSTALLER_URL}/package.use"
wget -q "${GENTOO_INSTALLER_URL}/package.license"
wget -q "${GENTOO_INSTALLER_URL}/package.mask"

echo CPU_FLAGS=\"$GENTOO_CPUFLAGS\" >> /etc/portage/make.conf
echo $GENTOO_CPUFLAGS >> /etc/portage/make.conf

# Make fstab
cat > /etc/fstab << 'FSTAB_BLOCK_END'
# /etc/fstab: static file system information.
FSTAB_BLOCK_END

echo "${TARGET_PART}1   /boot   vfat    noatime      0 0" >> /etc/fstab

if [[ "$SWAP_TYPE" == "partition" ]]; then
    echo "${TARGET_PART}3   /       f2fs    defaults,rw,noatime,compress_algorithm=zstd,compress_extension=*  0 0" >> /etc/fstab
    echo "${TARGET_PART}2   none    swap    sw      0 0" >> /etc/fstab
else
    echo "${TARGET_PART}2   /       f2fs    defaults,rw,noatime,compress_algorithm=zstd,compress_extension=*  0 0" >> /etc/fstab
fi

# System configuration
sed -i "s/localhost/$GENTOO_HOSTNAME/g" /etc/conf.d/hostname
sed -i "s/default8x16/$GENTOO_CONSOLEFONT/g" /etc/conf.d/consolefont
echo "127.0.0.1 $GENTOO_HOSTNAME.$GENTOO_DOMAINNAME $GENTOO_HOSTNAME localhost" >> /etc/hosts
sed -i 's/127.0.0.1/#127.0.0.1/g' /etc/hosts

# LAN configuration
if [[ "$NET_MODE" == "dhcp" ]]; then
    cat > /etc/dhcpcd.conf << 'DHCP_BLOCK_END'
# DHCP configuration
DHCP_BLOCK_END
    echo "interface ${TARGET_LAN}" >> /etc/dhcpcd.conf
    echo "# Use DHCP" >> /etc/dhcpcd.conf
else
    cat > /etc/dhcpcd.conf << 'STATIC_BLOCK_END'
# Static IP configuration
STATIC_BLOCK_END
    echo "interface ${TARGET_LAN}" >> /etc/dhcpcd.conf
    echo "static ip_address=${TARGET_IP}/${TARGET_CIDR}" >> /etc/dhcpcd.conf
    echo "static routers=${TARGET_GATE}" >> /etc/dhcpcd.conf
    echo "static domain_name_servers=${TARGET_DNS}" >> /etc/dhcpcd.conf
    echo "nodhcp" >> /etc/dhcpcd.conf
fi

# Backup LAN configuration
if [[ "$NET_MODE" == "dhcp" ]]; then
    echo "config_${TARGET_LAN}=\"dhcp\"" > /etc/conf.d/net
else
    echo "config_${TARGET_LAN}=\"${TARGET_IP} netmask ${TARGET_MASK}\"" > /etc/conf.d/net
    echo "routes_${TARGET_LAN}=\"default via ${TARGET_GATE}\"" >> /etc/conf.d/net
    echo "dns_${TARGET_LAN}=\"${TARGET_DNS}\"" >> /etc/conf.d/net
fi

# Keymap configuration
cat > /etc/conf.d/keymaps << 'KEYMAP_BLOCK_END'
keymap="us"
KEYMAP_BLOCK_END
sed -i "s/us/$GENTOO_KEYMAP/g" /etc/conf.d/keymaps

# Locale configuration
cat > /etc/locale.gen << 'LOCALE_BLOCK_END'
en_US.UTF-8 UTF-8
LOCALE_BLOCK_END
sed -i "s/en_US.UTF-8/$GENTOO_LOCALE/g" /etc/locale.gen

cat > /etc/env.d/02locale << 'LOCALE_ENV_BLOCK_END'
LANG="en_US.UTF-8"
LC_COLLATE="C"
LOCALE_ENV_BLOCK_END
sed -i "s/en_US.UTF-8/$GENTOO_LOCALE/g" /etc/env.d/02locale

locale-gen
echo "$GENTOO_ZONEINFO" > /etc/timezone
env-update && source /etc/profile

# Swap configuration
case "$SWAP_TYPE" in
    "zram")
        echo "Configuring ZRAM swap..."
        emerge sys-block/zram-init

        cat > /etc/conf.d/zram-init << 'ZRAM_BLOCK_END'
num_devices="1"
type0="swap"
size0=1024M
comp_alg0="zstd"
swap_priority0="100"
max_comp_streams0="1"
ZRAM_BLOCK_END

        # Update values
        sed -i "s/1024M/${ZRAM_SIZE}M/g" /etc/conf.d/zram-init
        sed -i "s/zstd/$ZRAM_ALGORITHM/g" /etc/conf.d/zram-init
        sed -i "s/num_devices=\"1\"/num_devices=\"$ZRAM_DEVICES\"/g" /etc/conf.d/zram-init
        sed -i "s/max_comp_streams0=\"1\"/max_comp_streams0=\"$ZRAM_DEVICES\"/g" /etc/conf.d/zram-init

        rc-update add zram-init default
        echo "ZRAM swap configured: ${ZRAM_SIZE}MB with ${ZRAM_ALGORITHM} compression"
        ;;

    "file")
        echo "Creating swap file..."
        fallocate -l ${SWAPFILE_SIZE}M ${SWAPFILE_PATH}
        chmod 600 ${SWAPFILE_PATH}
        mkswap ${SWAPFILE_PATH}
        echo "${SWAPFILE_PATH}   none    swap    sw      0 0" >> /etc/fstab
        echo "Swap file created: ${SWAPFILE_PATH} (${SWAPFILE_SIZE}MB)"
        ;;

    "partition")
        echo "Swap partition already configured in fstab"
        ;;

    "none")
        echo "No swap configured"
        ;;
esac

# Kernel and packages
emerge genkernel f2fs-tools dosfstools linux-firmware zen-sources && genkernel all
emerge grub terminus-font sudo

# GRUB configuration
cat >> /etc/default/grub << 'GRUB_BLOCK_END'
GRUB_GFXMODE=1920x1080x32
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_DISABLE_OS_PROBER=true
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_BLOCK_END

# Users and passwords
echo "root:$GENTOO_ROOT_PASSWORD" | chpasswd -c SHA256
useradd -m -G audio,video,usb,cdrom,portage,users,wheel -s /bin/bash $GENTOO_USER
echo "$GENTOO_USER:$GENTOO_USER_PASSWORD" | chpasswd -c SHA256

# Sudo configuration
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers

# GRUB Installation
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GENTOO --recheck ${TARGET_DISK}
grub-mkconfig -o /boot/grub/grub.cfg

# Services
rc-update add consolefont default && rc-update add numlock default && rc-update add sshd default

# Cleanup
rm -f /root/gentoo-chroot.sh
CHROOT_SCRIPT_END

log_info "✓ Entering chroot and starting installation"

# Starting chroot installation
chmod +x /mnt/gentoo/root/gentoo-chroot.sh
chroot /mnt/gentoo /root/gentoo-chroot.sh

#  Instalation Complete!
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║                    INSTALLATION COMPLETE !                     ║${RESET}"
echo -e "${GREEN}║    Your Gentoo Linux system has been successfully installed    ║${RESET}"
echo -e "${GREEN}║     You can now reboot and enjoy your new system! Lotrando     ║${RESET}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${RESET}"

log_info "✓ Installation completed successfully!"
