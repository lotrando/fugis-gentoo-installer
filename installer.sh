#!/bin/bash

# ╔════════════════════════════════════════════════════════════════════════════╗
# ║                  ███████╗ ██╗   ██╗  ██████╗  ██╗ ███████╗                 ║
# ║                  ██╔════╝ ██║   ██║ ██╔════╝  ██║ ██╔════╝                 ║
# ║                  █████╗   ██║   ██║ ██║  ███╗ ██║ ███████╗                 ║
# ║                  ██╔══╝   ██║   ██║ ██║   ██║ ██║ ╚════██║                 ║
# ║                  ██║      ╚██████╔╝ ╚██████╔╝ ██║ ███████║                 ║
# ║                  ╚═╝       ╚═════╝   ╚═════╝  ╚═╝ ╚══════╝                 ║
# ║                                                                            ║
# ║                  Fast Universal Gentoo Installation Script                 ║
# ║                   Created by Lotrando (c) 2024-2025 v 1.8                  ║
# ╚════════════════════════════════════════════════════════════════════════════╝

# Variables
GENTOO_INSTALLER_URL=https://raw.githubusercontent.com/lotrando/fugis-gentoo-installer/refs/heads/main
GENTOO_LOG_FILE="/tmp/fugis.log"

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

# Set default terminal type
export TERM=xterm-256color

# Clear the terminal
clear

# Strip ANSI color
strip_colors() {
    sed 's/\x1b\[[0-9;]*m//g'
}

# Umount partitions function
cleanup() {
    umount -Rf /mnt/gentoo 2>/dev/null || true
}

# Error handling
handle_error() {
    log_error "Script failed at line $1"
    cleanup
    exit 1
}

# Logging functions info
log_info() {
    local message="[INFO] $1"
    echo -e "${GREEN}${message}${RESET}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') $message" >> "$GENTOO_LOG_FILE"
}

# Logging functions error
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

# Detect CPU Cores
optimize_makeopts() {
    # Detect CPU makeopts
    GENTOO_MAKEOPTS="-j$(nproc)"
    log_info "✓ Detect MAKEOPTS: $GENTOO_MAKEOPTS"
}

# Detect CPU Flags
optimize_cpu_flags() {
    # Detect CPU flags
    GENTOO_CPUFLAGS=$(cpuid2cpuflags | sed 's/^CPU_FLAGS_X86: //')
    log_info "✓ Detect CPU flags: $GENTOO_CPUFLAGS"
}

# Detect GPU
detect_gpu() {
    # GPU specifické flagy
    if lspci | grep -i nvidia &>/dev/null; then
        GENTOO_GPU="nvidia"
        log_info "✓ Detected NVIDIA GPU"
    elif lspci | grep -i amd &>/dev/null; then
        GENTOO_GPU="amdgpu radeonsi"
        log_info "✓ Detected AMD GPU"
    elif lspci | grep -i intel &>/dev/null; then
        GENTOO_GPU="intel i965"
        log_info "✓ Detected Intel GPU"
    elif lspci | grep -i vmware &>/dev/null; then
        GENTOO_GPU="vmware"
        log_info "✓ Detected VMware virtual GPU"
    elif lspci | grep -i virtualbox &>/dev/null || lspci | grep -i "innotek" &>/dev/null; then
        GENTOO_GPU="virtualbox"
        log_info "✓ Detected VirtualBox virtual GPU"
    else
        GENTOO_GPU="fbdev vesa"
        log_info "✓ No specific GPU detected, using generic drivers"
    fi
}

# Convert Netmask to CDIR
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

# Validation IP
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

# Validation Hostname
validate_hostname() {
    local hostname=$1
    if [[ $hostname =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
        return 0
    fi
    return 1
}

# Validation Username
validate_username() {
    local username=$1
    if [[ $username =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]; then
        return 0
    fi
    return 1
}

# Configure SWAP partition
configure_swap_partition() {
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')

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

# Create partitions
create_disk_partitions() {
    log_info "✓ Creating partitions on ${TARGET_DISK}"

    # Set base device name (e.g. /dev/sda -> /dev/sda1, /dev/nvme0n1 -> /dev/nvme0n1p1)
    if [[ "${TARGET_DISK}" =~ nvme ]]; then
        PART_PREFIX="p"
    else
        PART_PREFIX=""
    fi

    if ! parted -s ${TARGET_DISK} mklabel gpt; then
        log_error "Failed to create GPT partition table"
        exit 1
    fi

    if [[ "$SWAP_TYPE" == "partition" ]]; then
        log_info "✓ Creating partitions with swap"

        parted -a optimal --script ${TARGET_DISK} \
            unit mib \
            mkpart primary fat32 1 ${UEFI_DISK_SIZE} \
            name 1 UEFI \
            set 1 esp on \
            mkpart primary ext4 ${UEFI_DISK_SIZE} $((UEFI_DISK_SIZE + BOOT_DISK_SIZE)) \
            name 2 BOOT \
            mkpart primary linux-swap $((UEFI_DISK_SIZE + BOOT_DISK_SIZE)) $((UEFI_DISK_SIZE + BOOT_DISK_SIZE + SWAP_SIZE)) \
            name 3 SWAP \
            mkpart primary ext4 $((UEFI_DISK_SIZE + BOOT_DISK_SIZE + SWAP_SIZE)) $((UEFI_DISK_SIZE + BOOT_DISK_SIZE + SWAP_SIZE + ROOT_DISK_SIZE)) \
            name 4 ROOT \
            mkpart primary ext4 $((UEFI_DISK_SIZE + BOOT_DISK_SIZE + SWAP_SIZE + ROOT_DISK_SIZE)) 100% \
            name 5 HOME

        log_info "✓ Creating swap partition"
        if ! mkswap -L SWAP "${TARGET_DISK}${PART_PREFIX}3"; then
            log_error "Failed to create swap partition"
            exit 1
        fi

        ROOT_PARTITION="${TARGET_DISK}${PART_PREFIX}4"

    else
        log_info "✓ Creating partitions without swap"

        parted -a optimal --script ${TARGET_DISK} \
            unit mib \
            mkpart primary fat32 1 ${UEFI_DISK_SIZE} \
            name 1 UEFI \
            set 1 esp on \
            mkpart primary ext4 ${UEFI_DISK_SIZE} $((UEFI_DISK_SIZE + BOOT_DISK_SIZE)) \
            name 2 BOOT \
            mkpart primary ext4 $((UEFI_DISK_SIZE + BOOT_DISK_SIZE)) $((UEFI_DISK_SIZE + BOOT_DISK_SIZE + ROOT_DISK_SIZE)) \
            name 3 ROOT \
            mkpart primary ext4 $((UEFI_DISK_SIZE + BOOT_DISK_SIZE + ROOT_DISK_SIZE)) 100% \
            name 4 HOME

        ROOT_PARTITION="${TARGET_DISK}${PART_PREFIX}3"
    fi
}

# Make filesystems
make_filesystems() {
    log_info "✓ Creating filesystems on UEFI and ROOT partitions"

    if ! mkfs.fat -n UEFI -F32 ${TARGET_PART}1 &>/dev/null; then
        log_error "Failed to create UEFI filesystem"
        exit 1
    fi

    if ! mkfs.f2fs -l ROOT -O extra_attr,inode_checksum,sb_checksum,compression -f ${ROOT_PARTITION} &>/dev/null; then
        log_error "Failed to create root filesystem"
        exit 1
    fi
}

# Mount filesystems
mount_filesystems() {
    log_info "✓ Mounting created filesystems"

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

    # Activvate swap if exists
    if [[ "$SWAP_TYPE" == "partition" ]]; then
        log_info "✓ Activating swap partition"
        swapon ${TARGET_PART}2
    fi
}

# Stage 3 download
stage_download() {
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
}

# Extract stage3
extract_stage() {
    log_info "✓ Extracting stage3: $STAGE3_FILENAME"
    if ! tar xpf ${STAGE3_FILENAME} --xattrs-include='*.*' --numeric-owner; then
        log_error "Failed to extract stage3 tarball"
        exit 1
    fi
}

# Input settings function
input_settings() {

    # Installation type selection
    echo ""
    echo -e "${LIGHT_MAGENTA}${UNDERLINE}Installation type:${RESET}"
    echo ""
    echo -e "${YELLOW}1.${RESET} ${WHITE}Classic (Clear Gentoo linux)${RESET}"
    echo -e "${YELLOW}2.${RESET} ${WHITE}Webserver (Clear Gentoo linux and LAMP server)${RESET}"
    echo -e "${YELLOW}3.${RESET} ${WHITE}Hyprland (Clear Gentoo linux and Hyprland Desktop)${RESET}"
    echo -e "${YELLOW}4.${RESET} ${WHITE}Webdevelop (Clear Gentoo linux and Hyprland Desktop, LAMP server and WBB Develop packages)${RESET}"

    while true; do
        echo ""
        read -p "$(echo -e "${BLUE}Choose installation type (1-4):${RESET} ")" install_choice
        case "$install_choice" in
            1)
                INSTALL_TYPE="classic"
                INSTALL_TYPE_NAME="Gentoo Linux Classic"
                echo -e "You have chosen: ${GREEN}${INSTALL_TYPE_NAME}${RESET}"
                break
                ;;
            2)
                INSTALL_TYPE="webserver"
                INSTALL_TYPE_NAME="Gentoo linux as LAMP server"
                echo -e "You have chosen: ${GREEN}${INSTALL_TYPE_NAME}${RESET}"
                break
                ;;
            3)
                INSTALL_TYPE="hyprland"
                INSTALL_TYPE_NAME="Gentoo Linux as Hyprland Desktop"
                echo -e "You have chosen: ${GREEN}${INSTALL_TYPE_NAME}${RESET}"
                break
                ;;
            4)
                INSTALL_TYPE="webdevelop"
                INSTALL_TYPE_NAME="Gentoo Linux as Hyprland Desktop, LAMP server and Develop packages"
                echo -e "You have chosen: ${GREEN}${INSTALL_TYPE_NAME}${RESET}"
                break
                ;;
            *)
                log_error "Invalid choice. Please try again."
                ;;
        esac
    done

    # Disk selection
    DISKS=($(lsblk -d -n -o NAME,TYPE | grep "disk" | grep -v "loop" | awk '{print "/dev/" $1}'))
    echo ""
    echo -e "${LIGHT_MAGENTA}${UNDERLINE}Detected disks:${RESET}"
    echo ""

    for i in "${!DISKS[@]}"; do
        disk_info=$(lsblk -d -n -o SIZE,MODEL "${DISKS[$i]}" 2>/dev/null | head -1)
        echo -e "${YELLOW}$((i+1)).${RESET} ${WHITE}${DISKS[$i]}${RESET} ${CYAN}($disk_info)${RESET}"
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

    # UEFI partition size input
    echo ""
    echo -e "${LIGHT_MAGENTA}${UNDERLINE}UEFI partition size in MB:${RESET}"
    echo ""
    while true; do
        read -p "Enter UEFI partition size [$(echo -e "${GREEN}${UEFI_DISK_SIZE:-1024}${RESET}")]: " input
        UEFI_DISK_SIZE=${input:-${UEFI_DISK_SIZE:-1024}}
        if [[ "$UEFI_DISK_SIZE" =~ ^[0-9]+$ ]] && [ "$UEFI_DISK_SIZE" -ge 1024 ]; then
            break
        else
            log_error "UEFI partition size must be >= 1024 MB"
        fi
    done

    # BOOT partition size input
    echo ""
    echo -e "${LIGHT_MAGENTA}${UNDERLINE}BOOT partition size in MB:${RESET}"
    echo ""
    while true; do
        read -p "Enter BOOT partition size [$(echo -e "${GREEN}${BOOT_DISK_SIZE:-2048}${RESET}")]: " input
        BOOT_DISK_SIZE=${input:-${BOOT_DISK_SIZE:-2048}}
        if [[ "$BOOT_DISK_SIZE" =~ ^[0-9]+$ ]] && [ "$BOOT_DISK_SIZE" -ge 2048 ]; then
            break
        else
            log_error "BOOT partition size must be >= 2048 MB"
        fi
    done

     # ROOT partition size input
    echo ""
    echo -e "${LIGHT_MAGENTA}${UNDERLINE}BOOT partition size in MB:${RESET}"
    echo ""
    while true; do
        read -p "Enter ROOT partition size [$(echo -e "${GREEN}${ROOT_DISK_SIZE:-2048}${RESET}")]: " input
        ROOT_DISK_SIZE=${input:-${ROOT_DISK_SIZE:-32000}}
        if [[ "$ROOT_DISK_SIZE" =~ ^[0-9]+$ ]] && [ "$ROOT_DISK_SIZE" -ge 32000 ]; then
            break
        else
            log_error "ROOT partition size must be >= 32 000 MB"
        fi
    done

    # SWAP configuration input
    echo ""
    echo -e "${LIGHT_MAGENTA}${UNDERLINE}SWAP config:${RESET}"
    echo ""
    echo -e "${YELLOW}1.${RESET} ${WHITE}SWAP Partition${RESET}"
    echo -e "${YELLOW}2.${RESET} ${WHITE}SWAP Off${RESET}"

    while true; do
        echo ""
        read -p "$(echo -e "${BLUE}Choose SWAP type (1-2):${RESET} ")" swap_choice
        case "$swap_choice" in
            1)
                SWAP_TYPE="partition"
                echo -e "You have chosen: ${GREEN}SWAP Partition${RESET}"
                configure_swap_partition
                break
                ;;
            2)
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

    # User name validation
    while true; do
        read -p "Enter username [$(echo -e "${GREEN}${GENTOO_USER:-user}${RESET}")]: " input
        GENTOO_USER=${input:-${GENTOO_USER:-user}}
        if validate_username "$GENTOO_USER"; then
            break
        else
            log_error "Invalid username format"
        fi
    done

    # User password validation
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

    # Root password validation
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

    # Hostname and domain validation
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

    # Kernel selection
    echo ""
    echo -e "${LIGHT_MAGENTA}${UNDERLINE}Kernel selection:${RESET}"
    echo ""
    echo -e "${YELLOW}1.${RESET} ${WHITE}Zen Sources (optimized for desktop)${RESET}"
    echo -e "${YELLOW}2.${RESET} ${WHITE}Git Sources (development kernel)${RESET}"
    echo -e "${YELLOW}3.${RESET} ${WHITE}Gentoo Sources (stable with Gentoo patches)${RESET}"

    while true; do
        echo ""
        read -p "$(echo -e "${BLUE}Choose kernel type (1-3):${RESET} ")" kernel_choice
        case "$kernel_choice" in
            1)
                GENTOO_KERNEL="zen-sources"
                KERNEL_NAME="Zen Sources"
                echo -e "You have chosen: ${GREEN}${KERNEL_NAME}${RESET}"
                break
                ;;
            2)
                GENTOO_KERNEL="git-sources"
                KERNEL_NAME="Git Sources"
                echo -e "You have chosen: ${GREEN}${KERNEL_NAME}${RESET}"
                break
                ;;
            3)
                GENTOO_KERNEL="gentoo-sources"
                KERNEL_NAME="Gentoo Sources"
                echo -e "You have chosen: ${GREEN}${KERNEL_NAME}${RESET}"
                break
                ;;
            *)
                log_error "Invalid choice. Please try again."
                ;;
        esac
    done

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

# Initialize clean log file
echo "--- FUGIS Installation Log ---" > "$GENTOO_LOG_FILE"
trap 'handle_error $LINENO' ERR
set -e
trap cleanup EXIT

# Installer header
HEADER_TEXT=(
    "               - F U G I S -               "
    " Fast Universal Gentoo Installation Script "
    "  Created by Lotrando (c) 2024-2025 v 1.8  "
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
for cmd in wget parted mkfs.fat mkfs.f2fs mkfs.ext4 curl; do
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

# Main input setting loop
while true; do
    input_settings

    # Summary and confirmation
    echo ""
    echo -e "${LIGHT_GREEN}${UNDERLINE}Summary of your settings:${RESET}"
    echo ""
    echo -e "${CYAN}Installation type:${RESET} ${INSTALL_TYPE_NAME}"
    echo -e "${CYAN}UEFI size:${RESET} ${UEFI_DISK_SIZE} MB"
    echo -e "${CYAN}BOOT size:${RESET} ${UEFI_DISK_SIZE} MB"
    echo -e "${CYAN}ROOT size:${RESET} ${UEFI_DISK_SIZE} MB"
    echo -e "${CYAN}Username:${RESET} ${GENTOO_USER}"
    echo -e "${CYAN}User password:${RESET} ${GENTOO_USER_PASSWORD}"
    echo -e "${CYAN}Root password:${RESET} ${GENTOO_ROOT_PASSWORD}"
    echo -e "${CYAN}Hostname:${RESET} ${GENTOO_HOSTNAME}"
    echo -e "${CYAN}Domain name:${RESET} ${GENTOO_DOMAINNAME}"
    echo -e "${CYAN}Kernel:${RESET} ${KERNEL_NAME}"
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
    fi
    echo ""
    echo -e "${RED}WARNING: Confirm will COMPLETELY WIPE the selected disk!${RESET}"
    echo ""
    read -n1 -p "$(echo -e "${YELLOW}Is everything set as you want? (y/n): ${RESET}")" confirm
    echo ""
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        break
    else
        clear
        echo -e "${RED}You chose to review your settings. Please re-enter your configuration.${RESET}"
    fi
done

# Installation starts here !!!
echo ""
log_info "✓ Starting installation process..."

detect_gpu
optimize_cpu_flags
optimize_makeopts
create_disk_partitions
make_filesystems
mount_filesystems
cd /mnt/gentoo
stage_download
extract_stage

# Setup system
mkdir -p /mnt/gentoo/var/db/repos/gentoo
mkdir -p /mnt/gentoo/etc/portage/repos.conf

# Copy repos.conf
if ! cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/; then
    log_error "Failed to copy repos.conf"
    exit 1
fi

# Copy resol.conf
if ! cp /etc/resolv.conf /mnt/gentoo/etc/; then
    log_error "Failed to copy resolv.conf"
    exit 1
fi

# Remove downloaded tarball
log_info "✓ Cleaning up downloaded tarball"
rm "$STAGE3_FILENAME"

log_info "✓ Mounting [proc sys dev run] filesystems"
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

# CIDR
if [[ "$NET_MODE" == "static" ]]; then
    TARGET_CIDR=$(netmask_to_cidr "$TARGET_MASK")
else
    TARGET_CIDR="24"  # default for DHCP (not used but defined)
fi

# Create config file
log_info "✓ Creating chroot configuration file"
cat > /mnt/gentoo/tmp/chroot_config << EOF
INSTALL_TYPE="$INSTALL_TYPE"
GENTOO_MAKEOPTS="$GENTOO_MAKEOPTS"
GENTOO_GPU="$GENTOO_GPU"
GENTOO_CPUFLAGS="$GENTOO_CPUFLAGS"
GENTOO_INSTALLER_URL="$GENTOO_INSTALLER_URL"
GENTOO_KERNEL="$GENTOO_KERNEL"
TARGET_PART="$TARGET_PART"
SWAP_TYPE="$SWAP_TYPE"
GENTOO_HOSTNAME="$GENTOO_HOSTNAME"
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
GRUB_GFX_MODE="$GRUB_GFX_MODE"
GENTOO_ROOT_PASSWORD="$GENTOO_ROOT_PASSWORD"
GENTOO_USER="$GENTOO_USER"
GENTOO_USER_PASSWORD="$GENTOO_USER_PASSWORD"
TARGET_DISK="$TARGET_DISK"
GENTOO_LOG_FILE="$GENTOO_LOG_FILE"
EOF

# Create improved chroot script
log_info "✓ Creating install script"
cat > /mnt/gentoo/root/gentoo-chroot.sh << 'CHROOT_SCRIPT_END'
#!/bin/bash

# Colors
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

log_info() {
    local message="[INFO] $1"
    echo -e "${GREEN}${message}${RESET}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') $message" >> "${GENTOO_LOG_FILE}"
}

log_error() {
    local message="[ERROR] $1"
    echo -e "${RED}${message}${RESET}" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S') $message" >> "${GENTOO_LOG_FILE}"
}

log_warning() {
    local message="[WARNING] $1"
    echo -e "${YELLOW}${message}${RESET}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') $message" >> "${GENTOO_LOG_FILE}"
}

# Chroot config load
source /tmp/chroot_config

log_info "✓ Starting chroot installation"

log_info "✓ Updating portage tree"
emerge-webrsync &>/dev/null
eselect news read new &>/dev/null

log_info "✓ Configuring portage"
cd /etc/portage/
rm -f make.conf
rm -rf package.use
rm -rf package.accept_keywords
rm -rf package.mask
wget -q "${GENTOO_INSTALLER_URL}/${INSTALL_TYPE}/make.conf"
wget -q "${GENTOO_INSTALLER_URL}/${INSTALL_TYPE}/package.accept_keywords"
wget -q "${GENTOO_INSTALLER_URL}/${INSTALL_TYPE}/package.use"
wget -q "${GENTOO_INSTALLER_URL}/${INSTALL_TYPE}/package.license"
wget -q "${GENTOO_INSTALLER_URL}/${INSTALL_TYPE}/package.mask"

log_info "✓ Configuring GPU"
if [[ -n "$GENTOO_GPU" ]]; then
    echo "VIDEO_CARDS=\"$GENTOO_GPU\"" >> make.conf
else
    echo "VIDEO_CARDS=\"fbdev vesa\"" >> make.conf
fi
log_info "✓ Configuring CPU FLAGS"
echo CPU_FLAGS_X86=\"$GENTOO_CPUFLAGS\" >> make.conf
log_info "✓ Configuring MAKEOPTS in make.conf"
echo MAKEOPTS=\"$GENTOO_MAKEOPTS\" >> make.conf

log_info "✓ Update /etc/fstab file"
cat > /etc/fstab << 'FSTAB_BLOCK_END'
# /etc/fstab: static file system information.
FSTAB_BLOCK_END

echo "${TARGET_PART}1   /efi    vfat    noatime      0 0" >> /etc/fstab
echo "${TARGET_PART}2   /boot   ext4    noatime      0 0" >> /etc/fstab

if [[ "$SWAP_TYPE" == "partition" ]]; then
    echo "${TARGET_PART}3   none    swap    sw      0 0" >> /etc/fstab
    echo "${TARGET_PART}4   /       f2fs    defaults,rw,noatime,compress_algorithm=zstd,compress_extension=*  0 0" >> /etc/fstab
    echo "${TARGET_PART}5   /home   f2fs    defaults,rw,noatime,compress_algorithm=zstd,compress_extension=*  0 0" >> /etc/fstab
else
    echo "${TARGET_PART}3   /       f2fs    defaults,rw,noatime,compress_algorithm=zstd,compress_extension=*  0 0" >> /etc/fstab
    echo "${TARGET_PART}4   /home   f2fs    defaults,rw,noatime,compress_algorithm=zstd,compress_extension=*  0 0" >> /etc/fstab
fi

log_info "✓ Setting [hostname, consolefont, hosts]"
sed -i "s/localhost/$GENTOO_HOSTNAME/g" /etc/conf.d/hostname
sed -i "s/default8x16/ter-v16b/g" /etc/conf.d/consolefont
echo "127.0.0.1 $GENTOO_HOSTNAME.$GENTOO_DOMAINNAME $GENTOO_HOSTNAME localhost" >> /etc/hosts
sed -i 's/127.0.0.1/#127.0.0.1/g' /etc/hosts

log_info "✓ Setting LAN"
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
if [[ "$NET_MODE" == "dhcp" ]]; then
    echo "config_${TARGET_LAN}=\"dhcp\"" > /etc/conf.d/net
else
    echo "config_${TARGET_LAN}=\"${TARGET_IP} netmask ${TARGET_MASK}\"" > /etc/conf.d/net
    echo "routes_${TARGET_LAN}=\"default via ${TARGET_GATE}\"" >> /etc/conf.d/net
    echo "dns_${TARGET_LAN}=\"${TARGET_DNS}\"" >> /etc/conf.d/net
fi

log_info "✓ Setting keymap"
cat > /etc/conf.d/keymaps << 'KEYMAP_BLOCK_END'
keymap="us"
KEYMAP_BLOCK_END
sed -i "s/us/$GENTOO_KEYMAP/g" /etc/conf.d/keymaps

log_info "✓ Setting locales"
cat > /etc/locale.gen << 'LOCALE_BLOCK_END'
en_US.UTF-8 UTF-8
LOCALE_BLOCK_END
sed -i "s/en_US.UTF-8/$GENTOO_LOCALE/g" /etc/locale.gen
cat > /etc/env.d/02locale << 'LOCALE_ENV_BLOCK_END'
LANG="en_US.UTF-8"
LC_COLLATE="C"
LOCALE_ENV_BLOCK_END
sed -i "s/en_US.UTF-8/$GENTOO_LOCALE/g" /etc/env.d/02locale

log_info "✓ Setting timezone"
locale-gen --quiet
echo "$GENTOO_ZONEINFO" > /etc/timezone
env-update >/dev/null 2>&1
source /etc/profile >/dev/null 2>&1

log_info "✓ Installing kernel packages"
emerge ${GENTOO_KERNEL}
echo ""
log_info "✓ Installing firmware"
emerge linux-firmware genkernel
echo ""
log_info "✓ Starting generate kernel"
echo ""
genkernel all
echo ""
log_info "✓ Installing important packages"
emerge f2fs-tools dosfstools grub terminus-font sudo btop app-misc/mc

log_info "✓ Create root password"
echo "root:$GENTOO_ROOT_PASSWORD" | chpasswd -c SHA256
log_info "✓ Create user $GENTOO_USER and his password"
useradd -m -G audio,video,usb,cdrom,portage,users,wheel -s /bin/bash $GENTOO_USER
echo "$GENTOO_USER:$GENTOO_USER_PASSWORD" | chpasswd -c SHA256

log_info "✓ Configuring SUDO for $GENTOO_USER"
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers

log_info "✓ Configuring GRUB and setting resolution ${GRUB_GFX_MODE}"
cat >> /etc/default/grub << GRUB_BLOCK_END
GRUB_GFXMODE=${GRUB_GFX_MODE}
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_BACKGROUND="/boot/grub/grub.png"
GRUB_DISABLE_OS_PROBER=true
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_BLOCK_END

log_info "✓ Installing GRUB and create config file"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GENTOO --recheck ${TARGET_DISK}
cd /boot/grub/
wget -q "${GENTOO_INSTALLER_URL}/${INSTALL_TYPE}/grub.png"
grub-mkconfig -o /boot/grub/grub.cfg

log_info "✓ Installing user configuration files"
cd /home/$GENTOO_USER/
wget -q "${GENTOO_INSTALLER_URL}/${INSTALL_TYPE}/dotfiles.zip"
unzip -qo dotfiles.zip
chown -R $GENTOO_USER:$GENTOO_USER /home/$GENTOO_USER
rm -f dotfiles.zip

log_info "✓ Running services"
rc-update add consolefont default && rc-update add numlock default && rc-update add sshd default && rc-update add gpm default

# Installation type specific packages and configuration
if [[ "$INSTALL_TYPE" == "classic" ]]; then
    log_info "✓ Installing additional packages"
    #emerge gentoolkit eix
elif [[ "$INSTALL_TYPE" == "webserver" || "$INSTALL_TYPE" == "webdevelop" ]]; then
    log_info "✓ Installing additional Webserver packages and configs"
    emerge phpmyadmin dev-db/mysql dev-lang/php
    eselect php set cli php8.4 && eselect php set apache2 php8.4
    rm -R /usr/lib/tmpfiles.d/mysql.conf
    echo "d /run/mysqld 0755 mysql mysql -" > /usr/lib/tmpfiles.d/mysql.conf
    sed -i 's/SSL_DEFAULT_VHOST/PHP/g' /etc/conf.d/apache2
    echo "ServerName localhost" >> /etc/apache2/httpd.conf
    rm -R /var/www/localhost/htdocs/index.html && echo "<?php phpinfo(); ?>" > /var/www/localhost/htdocs/index.php
    cp /var/www/localhost/htdocs/phpmyadmin/config.sample.inc.php /var/www/localhost/htdocs/phpmyadmin/config.inc.php
    mkdir /var/www/localhost/htdocs/phpmyadmin/tmp/
    chown -R apache:apache /var/www/ && usermod -aG apache realist
    chmod -R 775 /var/www/localhost/htdocs && chmod -R 777 /var/www/localhost/htdocs/phpmyadmin/tmp
    echo ""
    log_info "✓ Type mySQL root password"
    emerge --config mysql
    rc-update add apache2 default && rc-update add mysql default
elif [[ "$INSTALL_TYPE" == "hyprland" || "$INSTALL_TYPE" == "webdevelop" ]]; then
    log_info "✓ Installing additional Hyprland desktop packages"
    emerge eselect-repository procps pambase elogind sys-apps/dbus seatd eza
    eselect repository enable guru && emaint sync -r guru
    emerge hyprland hyprland-contrib xdg-desktop-portal-hyprland hyprlock hypridle hyprpaper hyprpicker waybar rofi-wayland wlogout kitty thunar pavucontrol
    eselect repository enable r7l && emaint sync -r r7l
    emerge oh-my-zsh gentoo-zsh-completions zsh-completions
    git clone https://github.com/romkatv/powerlevel10k.git /usr/share/zsh/site-contrib/oh-my-zsh/custom/themes/powerlevel10k
    git clone https://github.com/zsh-users/zsh-autosuggestions.git /usr/share/zsh/site-contrib/oh-my-zsh/custom/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /usr/share/zsh/site-contrib/oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    chsh -s /bin/zsh $GENTOO_USER
    rc-update add elogind boot && rc-update add dbus default

    #emerge gui-apps/wl-clipboard
    #emerge media-fonts/jetbrains-mono media-fonts/fontawesome media-fonts/nerd-fonts
    #emerge gui-apps/swaylock gui-apps/swww gui-apps/mako app-misc/brightnessctl
    #emerge gnome-extra/nm-applet net-misc/networkmanager net-wireless/blueman gnome-extra/polkit-gnome
elif [[ "$INSTALL_TYPE" == "webdevelop" ]]; then
    log_info "✓ Installing additional Web Development packages"
    emerge nodejs vscode composer
fi

log_info "✓ Removing chroot script"
rm -f /root/gentoo-chroot.sh
CHROOT_SCRIPT_END

chmod +x /mnt/gentoo/root/gentoo-chroot.sh
chroot /mnt/gentoo /root/gentoo-chroot.sh

log_info "✓ Gentoo Linux installation completed successfully!"
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║                    INSTALLATION COMPLETE !                     ║${RESET}"
echo -e "${GREEN}║    Your Gentoo Linux system has been successfully installed    ║${RESET}"
echo -e "${GREEN}║         You can now reboot and enjoy your new system!          ║${RESET}"
echo -e "${GREEN}║    After reboot for update packages from stage3 run command    ║${RESET}"
echo -e "${GREEN}╠════════════════════════════════════════════════════════════════╣${RESET}"
echo -e "${GREEN}║                  sudo emerge -avNUDu @world                    ║${RESET}"
elif [[ "$INSTALL_TYPE" == "webserver" || "$INSTALL_TYPE" == "webdevelop" ]]; then
echo -e "${GREEN}║                                                                ║${RESET}"
echo -e "${GREEN}║     for config phpmyadmin secret blowfish tokenrun command     ║${RESET}"
echo -e "${GREEN}║    nano /var/www/localhost/htdocs/phpmyadmin/config.inc.php    ║${RESET}"
echo -e "${GREEN}║           uncomment and set line in config file to             ║${RESET}"
echo -e "${GREEN}║ $cfg['blowfish_secret'] = 'WntN0150l71sLq/{w4V0:ZXFv7WcB-Qz';  ║${RESET}"
fi
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${RESET}"