#!/bin/bash

#################################################
# Complete Arch Linux Installation Script
# Author: THToufique(Ripp3r)
# Description: Interactive Arch installation with
# desktop environment and Hyprland support
#################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Log file
LOG_FILE="/tmp/arch_install_$(date +%Y%m%d_%H%M%S).log"
KEYMAP_LOG="/tmp/keybindings.txt"

# Functions
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

print_header() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ____  _        _             _       ___           _        _ _           
   |  _ \(_)_ __  / \   _ __ ___| |__   |_ _|_ __  ___| |_ __ _| | | ___ _ __ 
   | |_) | | '_ \/ _ \ | '__/ __| '_ \   | || '_ \/ __| __/ _` | | |/ _ \ '__|
   |  _ <| | |_) / ___ \| | | (__| | | |  | || | | \__ \ || (_| | | |  __/ |   
   |_| \_\_| .__/_/   \_\_|  \___|_| |_| |___|_| |_|___/\__\__,_|_|_|\___|_|   
           |_|                                                                  

EOF
    echo -e "${MAGENTA}                 Complete System Setup with Hyprland${NC}"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

pause() {
    read -p "Press Enter to continue..."
}

# Check if running on live media
check_live_environment() {
    print_header
    print_info "Checking if running on Arch Linux live media..."
    
    if [[ ! -f /etc/arch-release ]]; then
        print_error "This script must be run from Arch Linux live media!"
        exit 1
    fi
    
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        exit 1
    fi
    
    print_success "Running on Arch Linux live media"
    log "Installation started at $(date)"
}

# Check internet connection
check_internet() {
    print_header
    print_info "Checking internet connection..."
    
    if ping -c 3 archlinux.org &> /dev/null; then
        print_success "Internet connection is active"
    else
        print_error "No internet connection detected!"
        echo ""
        print_info "Please configure your internet connection:"
        echo "  For Ethernet: It should work automatically"
        echo "  For WiFi: Run 'iwctl' and configure wireless"
        echo ""
        exit 1
    fi
}

# Setup SSH for remote installation
setup_ssh() {
    print_header
    echo "Do you want to continue installation via SSH from another device?"
    echo "This allows you to connect from another computer on the same network."
    echo ""
    read -p "Setup SSH? (yes/no): " ssh_choice
    
    if [[ "$ssh_choice" != "yes" ]]; then
        print_info "Continuing with local installation"
        log "SSH setup: Skipped"
        return
    fi
    
    print_info "Setting up SSH server..."
    
    # Start SSH service
    systemctl start sshd
    
    # Set root password for SSH login
    print_info "Set a temporary root password for SSH connection:"
    passwd
    
    # Get IP address
    print_info "Detecting network configuration..."
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Network Information:${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    
    # Display all network interfaces with IPs
    ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | while read ip; do
        interface=$(ip -4 addr show | grep -B 2 "$ip" | head -1 | awk '{print $2}' | sed 's/://')
        echo -e "${YELLOW}Interface:${NC} $interface"
        echo -e "${YELLOW}IP Address:${NC} $ip"
        echo ""
    done
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    print_success "SSH server is running!"
    echo ""
    echo -e "${GREEN}To connect from another device on the same network:${NC}"
    echo ""
    
    # Get primary IP (first non-loopback)
    PRIMARY_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
    
    if [[ -n "$PRIMARY_IP" ]]; then
        echo -e "${CYAN}1. Open terminal on your other device${NC}"
        echo -e "${CYAN}2. Run:${NC} ${YELLOW}ssh root@$PRIMARY_IP${NC}"
        echo -e "${CYAN}3. Enter the password you just set${NC}"
        echo -e "${CYAN}4. Continue the installation from there${NC}"
    else
        print_warning "Could not detect IP address automatically"
        echo "Please check your network configuration with: ip addr"
    fi
    
    echo ""
    echo -e "${MAGENTA}══════════════════════════════════════════════════════════${NC}"
    print_warning "After connecting via SSH, you can close this terminal"
    print_warning "and continue the installation from your other device."
    echo -e "${MAGENTA}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    read -p "Press Enter once you've connected via SSH (or press Enter to continue here)..."
    
    log "SSH setup: Enabled, IP: $PRIMARY_IP"
    print_success "Continuing with installation..."
    pause
}

# Update mirrorlist
update_mirrors() {
    print_header
    print_info "Updating mirrorlist for fastest mirrors..."
    
    echo "Select your country/region for mirror selection:"
    echo ""
    echo "1) United States"
    echo "2) United Kingdom"
    echo "3) Germany"
    echo "4) India"
    echo "5) Australia"
    echo "6) Canada"
    echo "7) France"
    echo "8) Japan"
    echo "9) Brazil"
    echo "10) China"
    echo "11) Russia"
    echo "12) South Korea"
    echo "13) Netherlands"
    echo "14) Sweden"
    echo "15) Poland"
    echo "16) Spain"
    echo "17) Italy"
    echo "18) Turkey"
    echo "19) Mexico"
    echo "20) Argentina"
    echo "21) Bangladesh"
    echo "22) Pakistan"
    echo "23) Indonesia"
    echo "24) Singapore"
    echo "25) Malaysia"
    echo "26) Thailand"
    echo "27) Vietnam"
    echo "28) Philippines"
    echo "29) South Africa"
    echo "30) Egypt"
    echo "31) Custom (Enter country code manually)"
    echo "32) Skip mirror update (use default mirrors)"
    echo ""
    read -p "Enter your choice [1-32]: " mirror_choice
    
    case $mirror_choice in
        1) COUNTRY="US" ;;
        2) COUNTRY="GB" ;;
        3) COUNTRY="DE" ;;
        4) COUNTRY="IN" ;;
        5) COUNTRY="AU" ;;
        6) COUNTRY="CA" ;;
        7) COUNTRY="FR" ;;
        8) COUNTRY="JP" ;;
        9) COUNTRY="BR" ;;
        10) COUNTRY="CN" ;;
        11) COUNTRY="RU" ;;
        12) COUNTRY="KR" ;;
        13) COUNTRY="NL" ;;
        14) COUNTRY="SE" ;;
        15) COUNTRY="PL" ;;
        16) COUNTRY="ES" ;;
        17) COUNTRY="IT" ;;
        18) COUNTRY="TR" ;;
        19) COUNTRY="MX" ;;
        20) COUNTRY="AR" ;;
        21) COUNTRY="BD" ;;
        22) COUNTRY="PK" ;;
        23) COUNTRY="ID" ;;
        24) COUNTRY="SG" ;;
        25) COUNTRY="MY" ;;
        26) COUNTRY="TH" ;;
        27) COUNTRY="VN" ;;
        28) COUNTRY="PH" ;;
        29) COUNTRY="ZA" ;;
        30) COUNTRY="EG" ;;
        31) 
            echo ""
            echo "Common country codes: US, GB, DE, FR, IN, CN, JP, AU, etc."
            echo "For full list, visit: https://www.iso.org/iso-3166-country-codes.html"
            read -p "Enter 2-letter country code (e.g., BD, PK, NZ): " COUNTRY
            COUNTRY=$(echo "$COUNTRY" | tr '[:lower:]' '[:upper:]')
            ;;
        32) 
            print_info "Skipping mirror update, using default mirrors"
            log "Mirror update: Skipped"
            pause
            return 
            ;;
        *) 
            print_warning "Invalid choice, skipping mirror update"
            log "Mirror update: Skipped (invalid choice)"
            pause
            return 
            ;;
    esac
    
    if [[ -n "$COUNTRY" ]]; then
        print_info "Updating mirrors for country: $COUNTRY"
        
        # Install reflector if not present
        if ! command -v reflector &> /dev/null; then
            print_info "Installing reflector..."
            pacman -Sy --noconfirm reflector
        fi
        
        # Backup original mirrorlist
        cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
        
        # Update mirrorlist
        print_info "Fetching fastest mirrors... (this may take a moment)"
        if reflector --country "$COUNTRY" --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null; then
            print_success "Mirrorlist updated successfully for $COUNTRY!"
            log "Mirror country: $COUNTRY"
        else
            print_warning "Could not find mirrors for $COUNTRY, trying worldwide mirrors..."
            reflector --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
            print_success "Worldwide mirrors configured"
            log "Mirror country: Worldwide (fallback)"
        fi
    fi
    
    pause
}

# Detect disk type (GPT/MBR)
detect_disk_type() {
    print_header
    print_info "Detecting available disks..."
    
    lsblk -d -o NAME,SIZE,TYPE | grep disk
    echo ""
    read -p "Enter the disk to install to (e.g., sda, nvme0n1, vda): " DISK
    
    DISK="/dev/$DISK"
    
    if [[ ! -b "$DISK" ]]; then
        print_error "Disk $DISK does not exist!"
        exit 1
    fi
    
    print_info "Selected disk: $DISK"
    
    # Detect if system supports UEFI
    if [[ -d /sys/firmware/efi/efivars ]]; then
        BOOT_MODE="UEFI"
        PARTITION_TYPE="GPT"
        print_success "UEFI mode detected - will use GPT partition table"
    else
        BOOT_MODE="BIOS"
        PARTITION_TYPE="MBR"
        print_success "BIOS mode detected - will use MBR partition table"
    fi
    
    log "Disk: $DISK, Boot Mode: $BOOT_MODE, Partition Type: $PARTITION_TYPE"
}

# Select filesystem
select_filesystem() {
    print_header
    echo "Select filesystem type:"
    echo "1) ext4 (recommended, stable and reliable)"
    echo "2) btrfs (advanced features, snapshots, compression)"
    echo "3) xfs (high performance, good for large files)"
    echo "4) f2fs (optimized for flash storage/SSD)"
    read -p "Enter choice [1-4]: " fs_choice
    
    case $fs_choice in
        1) FILESYSTEM="ext4" ;;
        2) FILESYSTEM="btrfs" ;;
        3) FILESYSTEM="xfs" ;;
        4) FILESYSTEM="f2fs" ;;
        *) 
            print_warning "Invalid choice, defaulting to ext4"
            FILESYSTEM="ext4"
            ;;
    esac
    
    print_success "Selected filesystem: $FILESYSTEM"
    log "Filesystem: $FILESYSTEM"
    
    # Ask about encryption
    echo ""
    read -p "Do you want to encrypt your root partition? (yes/no): " encrypt_choice
    
    if [[ "$encrypt_choice" == "yes" ]]; then
        ENCRYPTION="yes"
        print_info "Encryption will be enabled"
        read -p "Enter encryption password: " -s ENCRYPT_PASS
        echo ""
        read -p "Confirm encryption password: " -s ENCRYPT_PASS_CONFIRM
        echo ""
        
        if [[ "$ENCRYPT_PASS" != "$ENCRYPT_PASS_CONFIRM" ]]; then
            print_error "Passwords do not match!"
            exit 1
        fi
        
        print_success "Encryption password set"
        log "Encryption: Enabled"
    else
        ENCRYPTION="no"
        print_info "Encryption disabled"
        log "Encryption: Disabled"
    fi
    
    pause
}

# Configure swap
configure_swap() {
    print_header
    echo "Select swap configuration:"
    echo ""
    echo "1) Traditional swap partition"
    echo "   → Uses disk space (HDD/SSD)"
    echo "   → Best for hibernation support"
    echo "   → Recommended if you have limited RAM"
    echo ""
    echo "2) Swap file"
    echo "   → Uses disk space (HDD/SSD)"
    echo "   → Flexible, can be resized later"
    echo "   → Good general purpose option"
    echo ""
    echo "3) zram (compressed RAM swap)"
    echo "   → Uses RAM (compressed), NO disk space"
    echo "   → Can be LARGER than physical RAM due to compression"
    echo "   → Example: 64GB zram on 16GB RAM is possible!"
    echo "   → Faster than disk swap"
    echo "   → Reduces SSD wear"
    echo "   → Good if you have 4GB+ RAM"
    echo ""
    echo "4) No swap"
    echo "   → No swap at all"
    echo "   → Only if you have plenty of RAM (16GB+)"
    echo ""
    read -p "Enter choice [1-4]: " swap_choice
    
    case $swap_choice in
        1)
            SWAP_TYPE="partition"
            echo ""
            echo "Recommended swap sizes (uses DISK space):"
            echo "  RAM <= 2GB   : 2x RAM (e.g., 4GB swap for 2GB RAM)"
            echo "  RAM 2-8GB    : 1x RAM (e.g., 8GB swap for 8GB RAM)"
            echo "  RAM > 8GB    : 8GB or 0.5x RAM"
            echo ""
            read -p "Enter swap size in GB (e.g., 4): " SWAP_SIZE
            print_success "Swap partition: ${SWAP_SIZE}GB (will use disk space)"
            log "Swap Type: Partition, Size: ${SWAP_SIZE}GB"
            ;;
        2)
            SWAP_TYPE="file"
            echo ""
            echo "Swap file will use DISK space."
            read -p "Enter swap file size in GB (e.g., 4): " SWAP_SIZE
            print_success "Swap file: ${SWAP_SIZE}GB (will use disk space)"
            log "Swap Type: File, Size: ${SWAP_SIZE}GB"
            ;;
        3)
            SWAP_TYPE="zram"
            echo ""
            echo "zram configuration (NO disk space used):"
            echo ""
            echo "Choose setup method:"
            echo "1) Simple - fraction of RAM (e.g., 0.5 = half of RAM)"
            echo "2) Advanced - specify exact size in GB (can be larger than RAM)"
            echo ""
            read -p "Enter choice [1-2]: " zram_method
            
            if [[ "$zram_method" == "2" ]]; then
                echo ""
                echo "You can set zram larger than your physical RAM!"
                echo "Examples:"
                echo "  - 16GB RAM → Can use 32GB, 64GB, or even 128GB zram"
                echo "  - 8GB RAM  → Can use 16GB, 32GB zram"
                echo "  - Due to compression, it works efficiently"
                echo ""
                read -p "Enter zram size in GB (e.g., 64): " ZRAM_SIZE
                ZRAM_FRACTION="custom"
                print_success "zram swap: ${ZRAM_SIZE}GB (NO disk space used)"
                log "Swap Type: zram, Size: ${ZRAM_SIZE}GB"
            else
                echo ""
                echo "Fraction method:"
                echo "  0.5 = 50% of RAM"
                echo "  1.0 = 100% of RAM (equals your RAM size)"
                echo "  2.0 = 200% of RAM (double your RAM size)"
                echo "  4.0 = 400% of RAM (4x your RAM size)"
                echo ""
                read -p "Enter zram fraction (e.g., 2.0 for double RAM): " ZRAM_FRACTION
                ZRAM_FRACTION=${ZRAM_FRACTION:-0.5}
                print_success "zram swap: ${ZRAM_FRACTION}x RAM (NO disk space used)"
                log "Swap Type: zram, Fraction: ${ZRAM_FRACTION}"
            fi
            ;;
        4)
            SWAP_TYPE="none"
            print_info "No swap configured"
            log "Swap Type: None"
            ;;
        *)
            print_warning "Invalid choice, defaulting to no swap"
            SWAP_TYPE="none"
            ;;
    esac
    
    pause
}

# Partition disk
partition_disk() {
    print_header
    print_warning "WARNING: This will erase all data on $DISK!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
    
    print_info "Partitioning disk $DISK..."
    
    # Unmount any mounted partitions
    umount -R /mnt 2>/dev/null || true
    
    if [[ "$BOOT_MODE" == "UEFI" ]]; then
        # GPT partitioning for UEFI
        print_info "Creating GPT partition table..."
        
        parted -s "$DISK" mklabel gpt
        parted -s "$DISK" mkpart primary fat32 1MiB 512MiB
        parted -s "$DISK" set 1 esp on
        
        # Calculate partition sizes
        if [[ "$SWAP_TYPE" == "partition" ]]; then
            SWAP_END=$((512 + SWAP_SIZE * 1024))
            parted -s "$DISK" mkpart primary linux-swap 512MiB ${SWAP_END}MiB
            parted -s "$DISK" mkpart primary ext4 ${SWAP_END}MiB 100%
        else
            parted -s "$DISK" mkpart primary ext4 512MiB 100%
        fi
        
        # Set partition variables
        if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
            BOOT_PARTITION="${DISK}p1"
            if [[ "$SWAP_TYPE" == "partition" ]]; then
                SWAP_PARTITION="${DISK}p2"
                ROOT_PARTITION="${DISK}p3"
            else
                ROOT_PARTITION="${DISK}p2"
            fi
        else
            BOOT_PARTITION="${DISK}1"
            if [[ "$SWAP_TYPE" == "partition" ]]; then
                SWAP_PARTITION="${DISK}2"
                ROOT_PARTITION="${DISK}3"
            else
                ROOT_PARTITION="${DISK}2"
            fi
        fi
        
        print_info "Formatting EFI partition..."
        mkfs.fat -F32 "$BOOT_PARTITION"
        
    else
        # MBR partitioning for BIOS
        print_info "Creating MBR partition table..."
        
        parted -s "$DISK" mklabel msdos
        
        if [[ "$SWAP_TYPE" == "partition" ]]; then
            SWAP_END=$((SWAP_SIZE * 1024))
            parted -s "$DISK" mkpart primary linux-swap 1MiB ${SWAP_END}MiB
            parted -s "$DISK" mkpart primary ext4 ${SWAP_END}MiB 100%
            parted -s "$DISK" set 2 boot on
        else
            parted -s "$DISK" mkpart primary ext4 1MiB 100%
            parted -s "$DISK" set 1 boot on
        fi
        
        # Set partition variables
        if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
            if [[ "$SWAP_TYPE" == "partition" ]]; then
                SWAP_PARTITION="${DISK}p1"
                ROOT_PARTITION="${DISK}p2"
            else
                ROOT_PARTITION="${DISK}p1"
            fi
        else
            if [[ "$SWAP_TYPE" == "partition" ]]; then
                SWAP_PARTITION="${DISK}1"
                ROOT_PARTITION="${DISK}2"
            else
                ROOT_PARTITION="${DISK}1"
            fi
        fi
    fi
    
    # Setup encryption if requested
    if [[ "$ENCRYPTION" == "yes" ]]; then
        print_info "Setting up LUKS encryption..."
        # Use a temporary file for secure password handling
        TEMP_PASS_FILE=$(mktemp)
        echo -n "$ENCRYPT_PASS" > "$TEMP_PASS_FILE"
        cryptsetup luksFormat "$ROOT_PARTITION" "$TEMP_PASS_FILE"
        cryptsetup open "$ROOT_PARTITION" cryptroot --key-file "$TEMP_PASS_FILE"
        rm -f "$TEMP_PASS_FILE"
        ROOT_PARTITION_MAPPED="/dev/mapper/cryptroot"
        print_success "Encryption setup complete!"
    else
        ROOT_PARTITION_MAPPED="$ROOT_PARTITION"
    fi
    
    # Format root partition with selected filesystem
    print_info "Formatting root partition with $FILESYSTEM..."
    case $FILESYSTEM in
        ext4)
            mkfs.ext4 -F "$ROOT_PARTITION_MAPPED"
            ;;
        btrfs)
            mkfs.btrfs -f "$ROOT_PARTITION_MAPPED"
            ;;
        xfs)
            mkfs.xfs -f "$ROOT_PARTITION_MAPPED"
            ;;
        f2fs)
            mkfs.f2fs -f "$ROOT_PARTITION_MAPPED"
            ;;
    esac
    
    # Setup swap if partition type
    if [[ "$SWAP_TYPE" == "partition" ]]; then
        print_info "Setting up swap partition..."
        mkswap "$SWAP_PARTITION"
        swapon "$SWAP_PARTITION"
        print_success "Swap partition activated"
    fi
    
    # Mount partitions
    print_info "Mounting partitions..."
    mount "$ROOT_PARTITION_MAPPED" /mnt
    
    # Create btrfs subvolumes if btrfs
    if [[ "$FILESYSTEM" == "btrfs" ]]; then
        print_info "Creating btrfs subvolumes..."
        btrfs subvolume create /mnt/@
        btrfs subvolume create /mnt/@home
        btrfs subvolume create /mnt/@snapshots
        umount /mnt
        mount -o subvol=@ "$ROOT_PARTITION_MAPPED" /mnt
        mkdir -p /mnt/home
        mkdir -p /mnt/.snapshots
        mount -o subvol=@home "$ROOT_PARTITION_MAPPED" /mnt/home
        mount -o subvol=@snapshots "$ROOT_PARTITION_MAPPED" /mnt/.snapshots
        print_success "Btrfs subvolumes created"
    fi
    
    if [[ "$BOOT_MODE" == "UEFI" ]]; then
        mkdir -p /mnt/boot/efi
        mount "$BOOT_PARTITION" /mnt/boot/efi
    fi
    
    print_success "Disk partitioned and mounted successfully!"
    log "Root partition: $ROOT_PARTITION (Mapped: $ROOT_PARTITION_MAPPED)"
    if [[ "$BOOT_MODE" == "UEFI" ]]; then
        log "Boot partition: $BOOT_PARTITION"
    fi
    if [[ "$SWAP_TYPE" == "partition" ]]; then
        log "Swap partition: $SWAP_PARTITION"
    fi
    pause
}

# Install base system
install_base_system() {
    print_header
    print_info "Installing base system..."
    
    # Initialize pacman keyring first
    print_info "Initializing pacman keyring..."
    pacman-key --init
    pacman-key --populate archlinux
    
    # Update archlinux-keyring to latest
    print_info "Updating keyring..."
    pacman -Sy --noconfirm archlinux-keyring
    
    # Install base packages
    PACKAGES="base base-devel linux linux-firmware nano vim networkmanager grub"
    
    # Add filesystem tools
    case $FILESYSTEM in
        btrfs) PACKAGES="$PACKAGES btrfs-progs" ;;
        xfs) PACKAGES="$PACKAGES xfsprogs" ;;
        f2fs) PACKAGES="$PACKAGES f2fs-tools" ;;
    esac
    
    # Add encryption tools if needed
    if [[ "$ENCRYPTION" == "yes" ]]; then
        PACKAGES="$PACKAGES cryptsetup"
    fi
    
    # Add UEFI tools if needed
    if [[ "$BOOT_MODE" == "UEFI" ]]; then
        PACKAGES="$PACKAGES efibootmgr"
    fi
    
    # Add zram tools if needed
    if [[ "$SWAP_TYPE" == "zram" ]]; then
        PACKAGES="$PACKAGES zram-generator"
    fi
    
    print_info "Installing packages (this may take a while)..."
    pacstrap -K /mnt $PACKAGES
    
    if [[ $? -ne 0 ]]; then
        print_error "Package installation failed!"
        print_info "Trying again with keyring refresh..."
        
        # Refresh keys and try again
        pacman-key --refresh-keys
        pacstrap -K /mnt $PACKAGES
        
        if [[ $? -ne 0 ]]; then
            print_error "Installation failed again. Please check your internet connection."
            exit 1
        fi
    fi
    
    print_success "Base system installed!"
    
    # Generate fstab
    print_info "Generating fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab
    print_success "fstab generated!"
    
    # Setup swap file if selected
    if [[ "$SWAP_TYPE" == "file" ]]; then
        print_info "Creating swap file..."
        dd if=/dev/zero of=/mnt/swapfile bs=1M count=$((SWAP_SIZE * 1024)) status=progress
        chmod 600 /mnt/swapfile
        mkswap /mnt/swapfile
        swapon /mnt/swapfile
        echo "/swapfile none swap defaults 0 0" >> /mnt/etc/fstab
        print_success "Swap file created and activated"
    fi
    
    # Setup zram if selected
    if [[ "$SWAP_TYPE" == "zram" ]]; then
        print_info "Configuring zram..."
        mkdir -p /mnt/etc/systemd/zram-generator.conf.d
        
        if [[ "$ZRAM_FRACTION" == "custom" ]]; then
            # Custom size in GB
            cat > /mnt/etc/systemd/zram-generator.conf << EOF
[zram0]
zram-size = $(($ZRAM_SIZE * 1024))
compression-algorithm = zstd
EOF
            print_success "zram configured with ${ZRAM_SIZE}GB"
        else
            # Fraction of RAM
            cat > /mnt/etc/systemd/zram-generator.conf << EOF
[zram0]
zram-size = ram * $ZRAM_FRACTION
compression-algorithm = zstd
EOF
            print_success "zram configured with ${ZRAM_FRACTION}x RAM"
        fi
    fi
    
    pause
}

# Configure system
configure_system() {
    print_header
    print_info "Configuring system..."
    
    # Timezone
    echo ""
    echo "Select timezone configuration method:"
    echo "1) Select from common timezones"
    echo "2) Enter timezone manually (Region/City format)"
    echo ""
    read -p "Enter choice [1-2]: " tz_method
    
    if [[ "$tz_method" == "2" ]]; then
        echo ""
        echo "Enter timezone in Region/City format"
        echo "Examples: America/New_York, Europe/London, Asia/Dhaka, Asia/Kolkata"
        echo "For full list, check: /usr/share/zoneinfo/"
        read -p "Enter timezone: " TIMEZONE
    else
        echo ""
        echo "Select timezone:"
        echo "1) America/New_York (EST/EDT)"
        echo "2) America/Los_Angeles (PST/PDT)"
        echo "3) America/Chicago (CST/CDT)"
        echo "4) Europe/London (GMT/BST)"
        echo "5) Europe/Paris (CET/CEST)"
        echo "6) Europe/Berlin (CET/CEST)"
        echo "7) Asia/Kolkata (IST)"
        echo "8) Asia/Dhaka (BST)"
        echo "9) Asia/Karachi (PKT)"
        echo "10) Asia/Tokyo (JST)"
        echo "11) Asia/Shanghai (CST)"
        echo "12) Asia/Dubai (GST)"
        echo "13) Asia/Singapore (SGT)"
        echo "14) Asia/Bangkok (ICT)"
        echo "15) Asia/Jakarta (WIB)"
        echo "16) Australia/Sydney (AEST/AEDT)"
        echo "17) Pacific/Auckland (NZST/NZDT)"
        echo "18) Africa/Cairo (EET)"
        echo "19) Africa/Johannesburg (SAST)"
        read -p "Enter choice [1-19]: " tz_choice
        
        case $tz_choice in
            1) TIMEZONE="America/New_York" ;;
            2) TIMEZONE="America/Los_Angeles" ;;
            3) TIMEZONE="America/Chicago" ;;
            4) TIMEZONE="Europe/London" ;;
            5) TIMEZONE="Europe/Paris" ;;
            6) TIMEZONE="Europe/Berlin" ;;
            7) TIMEZONE="Asia/Kolkata" ;;
            8) TIMEZONE="Asia/Dhaka" ;;
            9) TIMEZONE="Asia/Karachi" ;;
            10) TIMEZONE="Asia/Tokyo" ;;
            11) TIMEZONE="Asia/Shanghai" ;;
            12) TIMEZONE="Asia/Dubai" ;;
            13) TIMEZONE="Asia/Singapore" ;;
            14) TIMEZONE="Asia/Bangkok" ;;
            15) TIMEZONE="Asia/Jakarta" ;;
            16) TIMEZONE="Australia/Sydney" ;;
            17) TIMEZONE="Pacific/Auckland" ;;
            18) TIMEZONE="Africa/Cairo" ;;
            19) TIMEZONE="Africa/Johannesburg" ;;
            *) TIMEZONE="UTC" ;;
        esac
    fi
    
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
    arch-chroot /mnt hwclock --systohc
    print_success "Timezone set to $TIMEZONE"
    
    # Locale
    echo ""
    echo "Select locale configuration method:"
    echo "1) Select from common locales"
    echo "2) Enter locale manually"
    echo ""
    read -p "Enter choice [1-2]: " locale_method
    
    if [[ "$locale_method" == "2" ]]; then
        echo ""
        echo "Enter locale (e.g., en_US.UTF-8, en_GB.UTF-8, bn_BD.UTF-8)"
        echo "Common formats: language_COUNTRY.UTF-8"
        read -p "Enter locale: " LOCALE
    else
        echo ""
        echo "Select locale:"
        echo "1) en_US.UTF-8 (English - United States)"
        echo "2) en_GB.UTF-8 (English - United Kingdom)"
        echo "3) en_CA.UTF-8 (English - Canada)"
        echo "4) en_AU.UTF-8 (English - Australia)"
        echo "5) de_DE.UTF-8 (German - Germany)"
        echo "6) fr_FR.UTF-8 (French - France)"
        echo "7) es_ES.UTF-8 (Spanish - Spain)"
        echo "8) it_IT.UTF-8 (Italian - Italy)"
        echo "9) pt_BR.UTF-8 (Portuguese - Brazil)"
        echo "10) ru_RU.UTF-8 (Russian - Russia)"
        echo "11) ja_JP.UTF-8 (Japanese - Japan)"
        echo "12) zh_CN.UTF-8 (Chinese - China)"
        echo "13) ko_KR.UTF-8 (Korean - Korea)"
        echo "14) ar_SA.UTF-8 (Arabic - Saudi Arabia)"
        echo "15) hi_IN.UTF-8 (Hindi - India)"
        echo "16) bn_BD.UTF-8 (Bengali - Bangladesh)"
        echo "17) ur_PK.UTF-8 (Urdu - Pakistan)"
        echo "18) id_ID.UTF-8 (Indonesian - Indonesia)"
        echo "19) th_TH.UTF-8 (Thai - Thailand)"
        echo "20) vi_VN.UTF-8 (Vietnamese - Vietnam)"
        echo "21) tr_TR.UTF-8 (Turkish - Turkey)"
        echo "22) pl_PL.UTF-8 (Polish - Poland)"
        echo "23) nl_NL.UTF-8 (Dutch - Netherlands)"
        echo "24) sv_SE.UTF-8 (Swedish - Sweden)"
        read -p "Enter choice [1-24]: " locale_choice
        
        case $locale_choice in
            1) LOCALE="en_US.UTF-8" ;;
            2) LOCALE="en_GB.UTF-8" ;;
            3) LOCALE="en_CA.UTF-8" ;;
            4) LOCALE="en_AU.UTF-8" ;;
            5) LOCALE="de_DE.UTF-8" ;;
            6) LOCALE="fr_FR.UTF-8" ;;
            7) LOCALE="es_ES.UTF-8" ;;
            8) LOCALE="it_IT.UTF-8" ;;
            9) LOCALE="pt_BR.UTF-8" ;;
            10) LOCALE="ru_RU.UTF-8" ;;
            11) LOCALE="ja_JP.UTF-8" ;;
            12) LOCALE="zh_CN.UTF-8" ;;
            13) LOCALE="ko_KR.UTF-8" ;;
            14) LOCALE="ar_SA.UTF-8" ;;
            15) LOCALE="hi_IN.UTF-8" ;;
            16) LOCALE="bn_BD.UTF-8" ;;
            17) LOCALE="ur_PK.UTF-8" ;;
            18) LOCALE="id_ID.UTF-8" ;;
            19) LOCALE="th_TH.UTF-8" ;;
            20) LOCALE="vi_VN.UTF-8" ;;
            21) LOCALE="tr_TR.UTF-8" ;;
            22) LOCALE="pl_PL.UTF-8" ;;
            23) LOCALE="nl_NL.UTF-8" ;;
            24) LOCALE="sv_SE.UTF-8" ;;
            *) LOCALE="en_US.UTF-8" ;;
        esac
    fi
    
    echo "$LOCALE UTF-8" >> /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen
    echo "LANG=$LOCALE" > /mnt/etc/locale.conf
    print_success "Locale set to $LOCALE"
    
    # Hostname
    echo ""
    read -p "Enter hostname: " HOSTNAME
    echo "$HOSTNAME" > /mnt/etc/hostname
    
    cat > /mnt/etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF
    print_success "Hostname set to $HOSTNAME"
    
    log "Timezone: $TIMEZONE, Locale: $LOCALE, Hostname: $HOSTNAME"
    pause
}

# Create user
create_user() {
    print_header
    print_info "Creating user account..."
    
    read -p "Enter username: " USERNAME
    
    arch-chroot /mnt useradd -m -G wheel,audio,video,storage,optical -s /bin/bash "$USERNAME"
    
    # Set user password with retry
    while true; do
        echo "Set password for $USERNAME:"
        if arch-chroot /mnt passwd "$USERNAME"; then
            break
        else
            print_error "Failed to set user password. Please try again."
        fi
    done
    
    # Set root password with retry
    while true; do
        echo "Set root password:"
        if arch-chroot /mnt passwd; then
            break
        else
            print_error "Failed to set root password. Please try again."
        fi
    done
    
    # Enable sudo for wheel group
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers
    
    print_success "User $USERNAME created!"
    log "Username: $USERNAME"
}

# Install bootloader
install_bootloader() {
    print_header
    print_info "Installing GRUB bootloader..."
    
    # Configure GRUB for encryption if needed
    if [[ "$ENCRYPTION" == "yes" ]]; then
        print_info "Configuring GRUB for encryption..."
        UUID=$(blkid -s UUID -o value "$ROOT_PARTITION")
        sed -i "s|GRUB_CMDLINE_LINUX=\"\"|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$UUID:cryptroot root=/dev/mapper/cryptroot\"|" /mnt/etc/default/grub
        
        # Add encrypt hook to mkinitcpio
        sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block encrypt filesystems fsck)/' /mnt/etc/mkinitcpio.conf
        arch-chroot /mnt mkinitcpio -P
    fi
    
    if [[ "$BOOT_MODE" == "UEFI" ]]; then
        arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
    else
        arch-chroot /mnt grub-install --target=i386-pc "$DISK"
    fi
    
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    
    print_success "GRUB installed successfully!"
    pause
}

# Enable services
enable_services() {
    print_header
    print_info "Enabling essential services..."
    
    arch-chroot /mnt systemctl enable NetworkManager
    
    print_success "Services enabled!"
}

# Install desktop environment
install_desktop_environment() {
    print_header
    echo "Do you want to install a Desktop Environment?"
    read -p "Enter choice (yes/no): " install_de
    
    if [[ "$install_de" != "yes" ]]; then
        print_info "Skipping desktop environment installation"
        return
    fi
    
    echo ""
    echo "Select Desktop Environment:"
    echo "1) KDE Plasma"
    echo "2) GNOME"
    echo "3) XFCE"
    echo "4) MATE"
    echo "5) Cinnamon"
    echo "6) LXQt"
    echo "7) None (skip)"
    read -p "Enter choice [1-7]: " de_choice
    
    case $de_choice in
        1)
            print_info "Installing KDE Plasma..."
            arch-chroot /mnt pacman -S --noconfirm xorg plasma plasma-wayland-session kde-applications sddm
            arch-chroot /mnt systemctl enable sddm
            log "Desktop Environment: KDE Plasma"
            ;;
        2)
            print_info "Installing GNOME..."
            arch-chroot /mnt pacman -S --noconfirm xorg gnome gnome-extra gdm
            arch-chroot /mnt systemctl enable gdm
            log "Desktop Environment: GNOME"
            ;;
        3)
            print_info "Installing XFCE..."
            arch-chroot /mnt pacman -S --noconfirm xorg xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
            arch-chroot /mnt systemctl enable lightdm
            log "Desktop Environment: XFCE"
            ;;
        4)
            print_info "Installing MATE..."
            arch-chroot /mnt pacman -S --noconfirm xorg mate mate-extra lightdm lightdm-gtk-greeter
            arch-chroot /mnt systemctl enable lightdm
            log "Desktop Environment: MATE"
            ;;
        5)
            print_info "Installing Cinnamon..."
            arch-chroot /mnt pacman -S --noconfirm xorg cinnamon lightdm lightdm-gtk-greeter
            arch-chroot /mnt systemctl enable lightdm
            log "Desktop Environment: Cinnamon"
            ;;
        6)
            print_info "Installing LXQt..."
            arch-chroot /mnt pacman -S --noconfirm xorg lxqt breeze-icons sddm
            arch-chroot /mnt systemctl enable sddm
            log "Desktop Environment: LXQt"
            ;;
        7)
            print_info "Skipping desktop environment"
            return
            ;;
    esac
    
    print_success "Desktop environment installed!"
    pause
}

# Install Hyprland
install_hyprland() {
    print_header
    echo "Do you want to install Hyprland?"
    read -p "Enter choice (yes/no): " install_hypr
    
    if [[ "$install_hypr" != "yes" ]]; then
        print_info "Skipping Hyprland installation"
        return
    fi
    
    echo ""
    echo "Select Hyprland setup type:"
    echo "1) Regular Hyprland (keyboard-focused, minimal)"
    echo "2) Hyprland with mouse support and window decorations (recommended)"
    read -p "Enter choice [1-2]: " hypr_choice
    
    print_info "Installing Hyprland and dependencies..."
    
    # Install base Hyprland packages
    arch-chroot /mnt pacman -S --noconfirm \
        hyprland \
        kitty \
        waybar \
        wofi \
        dunst \
        swww \
        swaylock \
        xdg-desktop-portal-hyprland \
        polkit-kde-agent \
        qt5-wayland \
        qt6-wayland \
        pipewire \
        pipewire-audio \
        pipewire-pulse \
        wireplumber \
        grim \
        slurp \
        wl-clipboard \
        brightnessctl \
        playerctl \
        pavucontrol \
        network-manager-applet \
        bluez \
        bluez-utils \
        blueman \
        noto-fonts \
        noto-fonts-emoji \
        ttf-jetbrains-mono-nerd \
        ttf-font-awesome \
        papirus-icon-theme \
        thunar \
        firefox \
        git
    
    # Enable Bluetooth
    arch-chroot /mnt systemctl enable bluetooth
    
    # Create Hyprland config
    USER_HOME="/mnt/home/$USERNAME"
    mkdir -p "$USER_HOME/.config/hypr"
    mkdir -p "$USER_HOME/.config/waybar"
    mkdir -p "$USER_HOME/.config/kitty"
    mkdir -p "$USER_HOME/.config/wofi"
    mkdir -p "$USER_HOME/Pictures/Wallpapers"
    
    if [[ "$hypr_choice" == "2" ]]; then
        # Enhanced config with mouse support
        create_hyprland_config_enhanced "$USER_HOME"
        log "Hyprland Type: Enhanced with mouse support and decorations"
    else
        # Regular minimal config
        create_hyprland_config_regular "$USER_HOME"
        log "Hyprland Type: Regular minimal setup"
    fi
    
    # Create other configs
    create_waybar_config "$USER_HOME"
    create_kitty_config "$USER_HOME"
    create_wofi_config "$USER_HOME"
    
    # Set permissions
    arch-chroot /mnt chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"
    
    # Create keybindings documentation
    create_keybindings_doc "$USER_HOME"
    
    print_success "Hyprland installed successfully!"
    log "Hyprland installation completed"
    pause
}

# Create Hyprland config (Enhanced)
create_hyprland_config_enhanced() {
    local user_home="$1"
    
    cat > "$user_home/.config/hypr/hyprland.conf" << 'EOF'
# Hyprland Configuration - Enhanced with Mouse Support
# Monitor configuration
monitor=,preferred,auto,1

# Execute at launch
exec-once = waybar
exec-once = dunst
exec-once = swww init
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = nm-applet
exec-once = blueman-applet

# Environment variables
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt5ct
env = QT_QPA_PLATFORM,wayland
env = GDK_BACKEND,wayland,x11

# Input configuration
input {
    kb_layout = us
    follow_mouse = 1
    
    touchpad {
        natural_scroll = true
        disable_while_typing = true
        tap-to-click = true
    }
    
    sensitivity = 0
    accel_profile = flat
}

# General settings
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
    allow_tearing = false
}

# Decoration
decoration {
    rounding = 10
    
    blur {
        enabled = true
        size = 6
        passes = 3
        new_optimizations = true
        ignore_opacity = true
    }
    
    drop_shadow = true
    shadow_range = 20
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

# Animations
animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 5, myBezier
    animation = windowsOut, 1, 5, default, popin 80%
    animation = border, 1, 8, default
    animation = borderangle, 1, 6, default
    animation = fade, 1, 5, default
    animation = workspaces, 1, 4, default
}

# Layouts
dwindle {
    pseudotile = true
    preserve_split = true
}

master {
    new_is_master = true
}

# Gestures
gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
}

# Window rules
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(blueman-manager)$
windowrule = float, ^(nm-connection-editor)$
windowrule = float, ^(thunar)$
windowrulev2 = opacity 0.90 0.90,class:^(kitty)$

# Key bindings
$mainMod = SUPER

# Applications
bind = $mainMod, Return, exec, kitty
bind = $mainMod, Q, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating,
bind = $mainMod, D, exec, wofi --show drun
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,
bind = $mainMod, F, fullscreen,
bind = $mainMod, L, exec, swaylock
bind = $mainMod, B, exec, firefox

# Move focus with mainMod + arrow keys
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Move focus with mainMod + hjkl
bind = $mainMod, h, movefocus, l
bind = $mainMod, semicolon, movefocus, r
bind = $mainMod, k, movefocus, u
bind = $mainMod, j, movefocus, d

# Switch workspaces with mainMod + [0-9]
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move active window to a workspace with mainMod + SHIFT + [0-9]
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Scroll through existing workspaces with mainMod + scroll
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Move/resize windows with mainMod + LMB/RMB and dragging
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Screenshots
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
bind = SHIFT, Print, exec, grim ~/Pictures/screenshot_$(date +%Y%m%d_%H%M%S).png

# Media keys
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous
bind = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
EOF
}

# Create Hyprland config (Regular)
create_hyprland_config_regular() {
    local user_home="$1"
    
    cat > "$user_home/.config/hypr/hyprland.conf" << 'EOF'
# Hyprland Configuration - Regular Minimal Setup
monitor=,preferred,auto,1

exec-once = waybar
exec-once = dunst

env = XCURSOR_SIZE,24

input {
    kb_layout = us
    follow_mouse = 1
}

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee)
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

decoration {
    rounding = 5
}

$mainMod = SUPER

bind = $mainMod, Return, exec, kitty
bind = $mainMod, Q, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating,
bind = $mainMod, D, exec, wofi --show drun
bind = $mainMod, F, fullscreen,

bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10
EOF
}

# Create Waybar config
create_waybar_config() {
    local user_home="$1"
    
    cat > "$user_home/.config/waybar/config" << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 35,
    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "cpu", "memory", "battery", "tray"],
    
    "hyprland/workspaces": {
        "format": "{id}"
    },
    
    "clock": {
        "format": "{:%H:%M  %d/%m/%Y}"
    },
    
    "cpu": {
        "format": " {usage}%"
    },
    
    "memory": {
        "format": " {}%"
    },
    
    "battery": {
        "format": "{icon} {capacity}%",
        "format-icons": ["", "", "", "", ""]
    },
    
    "network": {
        "format-wifi": " {signalStrength}%",
        "format-ethernet": " Connected"
    },
    
    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-icons": ["", "", ""]
    }
}
EOF

    cat > "$user_home/.config/waybar/style.css" << 'EOF'
* {
    font-family: "JetBrainsMono Nerd Font";
    font-size: 13px;
}

window#waybar {
    background: rgba(30, 30, 46, 0.9);
    color: #cdd6f4;
}

#workspaces button {
    padding: 0 10px;
    color: #cdd6f4;
}

#workspaces button.active {
    color: #89b4fa;
}
EOF
}

# Create Kitty config
create_kitty_config() {
    local user_home="$1"
    
    cat > "$user_home/.config/kitty/kitty.conf" << 'EOF'
font_family JetBrainsMono Nerd Font
font_size 12.0
background_opacity 0.90
window_padding_width 10

# Catppuccin Mocha theme
foreground #CDD6F4
background #1E1E2E
color0 #45475A
color1 #F38BA8
color2 #A6E3A1
color3 #F9E2AF
color4 #89B4FA
color5 #F5C2E7
color6 #94E2D5
color7 #BAC2DE
EOF
}

# Create Wofi config
create_wofi_config() {
    local user_home="$1"
    
    cat > "$user_home/.config/wofi/config" << 'EOF'
width=600
height=400
location=center
show=drun
prompt=Search...
allow_images=true
image_size=40
EOF

    cat > "$user_home/.config/wofi/style.css" << 'EOF'
window {
    background-color: #1e1e2e;
    border: 2px solid #89b4fa;
    border-radius: 10px;
}

#input {
    color: #cdd6f4;
    background-color: #313244;
    border-radius: 5px;
}

#entry:selected {
    background-color: #313244;
}
EOF
}

# Create keybindings documentation
create_keybindings_doc() {
    local user_home="$1"
    
    cat > "$user_home/HYPRLAND_KEYBINDINGS.txt" << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║            HYPRLAND KEYBINDINGS REFERENCE                      ║
╚════════════════════════════════════════════════════════════════╝

SUPER (MOD) KEY = Windows Key / Command Key

═══════════════════════════════════════════════════════════════
APPLICATIONS
═══════════════════════════════════════════════════════════════
SUPER + Return          → Open Terminal (Kitty)
SUPER + D               → Application Launcher (Wofi)
SUPER + E               → File Manager (Thunar)
SUPER + B               → Web Browser (Firefox)
SUPER + L               → Lock Screen

═══════════════════════════════════════════════════════════════
WINDOW MANAGEMENT
═══════════════════════════════════════════════════════════════
SUPER + Q               → Close Active Window
SUPER + V               → Toggle Floating Mode
SUPER + F               → Fullscreen Toggle
SUPER + P               → Pseudo Tiling
SUPER + J               → Toggle Split
SUPER + M               → Exit Hyprland

═══════════════════════════════════════════════════════════════
NAVIGATION (Arrow Keys)
═══════════════════════════════════════════════════════════════
SUPER + Left            → Move Focus Left
SUPER + Right           → Move Focus Right
SUPER + Up              → Move Focus Up
SUPER + Down            → Move Focus Down

═══════════════════════════════════════════════════════════════
NAVIGATION (Vim Keys)
═══════════════════════════════════════════════════════════════
SUPER + H               → Move Focus Left
SUPER + L               → Move Focus Right
SUPER + K               → Move Focus Up
SUPER + J               → Move Focus Down

═══════════════════════════════════════════════════════════════
WORKSPACES
═══════════════════════════════════════════════════════════════
SUPER + [1-9,0]         → Switch to Workspace 1-10
SUPER + SHIFT + [1-9,0] → Move Window to Workspace 1-10
SUPER + Mouse Scroll    → Cycle Through Workspaces

═══════════════════════════════════════════════════════════════
MOUSE CONTROLS
═══════════════════════════════════════════════════════════════
SUPER + Left Click Drag → Move Window
SUPER + Right Click Drag → Resize Window
Click on Window         → Focus Window

═══════════════════════════════════════════════════════════════
SCREENSHOTS
═══════════════════════════════════════════════════════════════
Print Screen            → Screenshot (Select Area, Copy to Clipboard)
SHIFT + Print Screen    → Screenshot (Full Screen, Save to ~/Pictures)

═══════════════════════════════════════════════════════════════
MEDIA CONTROLS
═══════════════════════════════════════════════════════════════
XF86AudioRaiseVolume    → Volume Up
XF86AudioLowerVolume    → Volume Down
XF86AudioMute           → Mute/Unmute
XF86AudioPlay           → Play/Pause
XF86AudioNext           → Next Track
XF86AudioPrev           → Previous Track
XF86MonBrightnessUp     → Brightness Up
XF86MonBrightnessDown   → Brightness Down

═══════════════════════════════════════════════════════════════
ADDITIONAL TIPS
═══════════════════════════════════════════════════════════════
• Configuration file: ~/.config/hypr/hyprland.conf
• Waybar config: ~/.config/waybar/
• Terminal config: ~/.config/kitty/kitty.conf
• App launcher config: ~/.config/wofi/

• To start Hyprland from TTY: type "Hyprland"
• Edit configs with: nano ~/.config/hypr/hyprland.conf
• Reload Hyprland: SUPER + SHIFT + R (if configured)

═══════════════════════════════════════════════════════════════
TROUBLESHOOTING
═══════════════════════════════════════════════════════════════
• No display? Check: ~/.config/hypr/hyprland.conf
• Waybar not showing? Run: waybar
• Can't launch apps? Check: wofi --show drun

For more help, visit: https://wiki.hyprland.org
EOF

    # Also save to installation log
    cat "$user_home/HYPRLAND_KEYBINDINGS.txt" >> "$KEYMAP_LOG"
}

# Finalize installation
finalize_installation() {
    print_header
    print_info "Finalizing installation..."
    
    # Copy log files to new system
    cp "$LOG_FILE" "/mnt/home/$USERNAME/installation_log_$(date +%Y%m%d_%H%M%S).txt"
    
    if [[ -f "$KEYMAP_LOG" ]]; then
        cp "$KEYMAP_LOG" "/mnt/home/$USERNAME/"
    fi
    
    # Set ownership
    arch-chroot /mnt chown "$USERNAME:$USERNAME" "/home/$USERNAME/installation_log_"*.txt
    arch-chroot /mnt chown "$USERNAME:$USERNAME" "/home/$USERNAME/HYPRLAND_KEYBINDINGS.txt" 2>/dev/null || true
    
    print_success "Installation logs saved to /home/$USERNAME/"
    
    # Create post-install info
    cat > "/mnt/home/$USERNAME/POST_INSTALL_INFO.txt" << EOF
╔════════════════════════════════════════════════════════════════╗
║          ARCH LINUX INSTALLATION COMPLETE                      ║
╚════════════════════════════════════════════════════════════════╝

Installation Date: $(date)
Hostname: $HOSTNAME
Username: $USERNAME
Timezone: $TIMEZONE
Locale: $LOCALE

Boot Mode: $BOOT_MODE
Disk: $DISK
Filesystem: $FILESYSTEM
Encryption: $ENCRYPTION
Root Partition: $ROOT_PARTITION
$(if [[ "$BOOT_MODE" == "UEFI" ]]; then echo "Boot Partition: $BOOT_PARTITION"; fi)

Swap Configuration: $SWAP_TYPE
$(if [[ "$SWAP_TYPE" == "partition" ]] || [[ "$SWAP_TYPE" == "file" ]]; then echo "Swap Size: ${SWAP_SIZE}GB"; fi)
$(if [[ "$SWAP_TYPE" == "zram" ]]; then echo "Zram Size: ${ZRAM_FRACTION}x RAM"; fi)

═══════════════════════════════════════════════════════════════
NEXT STEPS
═══════════════════════════════════════════════════════════════

1. Reboot your system:
   $ reboot

2. After reboot, login with your username and password
   $(if [[ "$ENCRYPTION" == "yes" ]]; then echo "   NOTE: Enter encryption password at boot prompt first"; fi)

3. If you installed a Desktop Environment:
   - It should start automatically

4. If you installed Hyprland:
   - Login to TTY
   - Type: Hyprland
   - See HYPRLAND_KEYBINDINGS.txt for keyboard shortcuts

5. Connect to WiFi (if needed):
   $ nmtui

6. Update system:
   $ sudo pacman -Syu

═══════════════════════════════════════════════════════════════
FILESYSTEM SPECIFIC NOTES
═══════════════════════════════════════════════════════════════

$(if [[ "$FILESYSTEM" == "btrfs" ]]; then
    echo "Btrfs Features:"
    echo "- Snapshots: Use 'sudo btrfs subvolume snapshot' to create snapshots"
    echo "- Compression: Enable with 'compress=zstd' mount option"
    echo "- Snapshots directory: /.snapshots"
    echo ""
    echo "Useful commands:"
    echo "  sudo btrfs subvolume list /"
    echo "  sudo btrfs filesystem df /"
    echo "  sudo btrfs subvolume snapshot / /.snapshots/snap-\$(date +%Y%m%d)"
fi)

$(if [[ "$SWAP_TYPE" == "zram" ]]; then
    echo "Zram Swap:"
    echo "- Check status: zramctl"
    echo "- Compressed swap using ${ZRAM_FRACTION}x RAM"
    echo "- No disk space used"
fi)

$(if [[ "$ENCRYPTION" == "yes" ]]; then
    echo "Encryption Notes:"
    echo "- You will be prompted for password at every boot"
    echo "- Keep your password safe - data is unrecoverable without it"
    echo "- To change password: sudo cryptsetup luksChangeKey $ROOT_PARTITION"
fi)

═══════════════════════════════════════════════════════════════
INSTALLED COMPONENTS
═══════════════════════════════════════════════════════════════

Base System: ✓
NetworkManager: ✓
GRUB Bootloader: ✓
Filesystem Tools ($FILESYSTEM): ✓
$(if [[ "$ENCRYPTION" == "yes" ]]; then echo "LUKS Encryption: ✓"; fi)
$(if [[ -n "$de_choice" ]] && [[ "$de_choice" != "7" ]]; then echo "Desktop Environment: ✓"; fi)
$(if [[ "$install_hypr" == "yes" ]]; then echo "Hyprland: ✓"; fi)

═══════════════════════════════════════════════════════════════
USEFUL COMMANDS
═══════════════════════════════════════════════════════════════

Check network status:    nmcli device status
Connect to WiFi:         nmtui
Update system:           sudo pacman -Syu
Install packages:        sudo pacman -S package-name
Search packages:         pacman -Ss search-term
Enable service:          sudo systemctl enable service-name
Start service:           sudo systemctl start service-name
$(if [[ "$SWAP_TYPE" != "none" ]]; then echo "Check swap:              free -h"; fi)
$(if [[ "$SWAP_TYPE" == "zram" ]]; then echo "Check zram:              zramctl"; fi)

═══════════════════════════════════════════════════════════════

Installation logs available in this directory.
For Hyprland keybindings, see: HYPRLAND_KEYBINDINGS.txt

Enjoy your new Arch Linux system!
EOF

    arch-chroot /mnt chown "$USERNAME:$USERNAME" "/home/$USERNAME/POST_INSTALL_INFO.txt"
    
    print_success "Post-install information saved!"
}

# Main installation function
main() {
    check_live_environment
    check_internet
    setup_ssh
    update_mirrors
    detect_disk_type
    select_filesystem
    configure_swap
    partition_disk
    install_base_system
    configure_system
    create_user
    install_bootloader
    enable_services
    install_desktop_environment
    install_hyprland
    finalize_installation
    
    print_header
    print_success "════════════════════════════════════════════════════════"
    print_success "   ARCH LINUX INSTALLATION COMPLETED SUCCESSFULLY!      "
    print_success "════════════════════════════════════════════════════════"
    echo ""
    echo -e "${CYAN}INSTALLATION SUMMARY:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Hostname:        $HOSTNAME"
    echo "Username:        $USERNAME"
    echo "Timezone:        $TIMEZONE"
    echo "Locale:          $LOCALE"
    echo "Boot Mode:       $BOOT_MODE"
    echo "Disk:            $DISK"
    echo "Filesystem:      $FILESYSTEM"
    echo "Encryption:      $ENCRYPTION"
    echo "Swap Type:       $SWAP_TYPE"
    if [[ "$SWAP_TYPE" == "partition" ]] || [[ "$SWAP_TYPE" == "file" ]]; then
        echo "Swap Size:       ${SWAP_SIZE}GB"
    elif [[ "$SWAP_TYPE" == "zram" ]]; then
        echo "Zram Size:       ${ZRAM_FRACTION}x RAM"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    print_info "Installation logs saved to:"
    print_info "  → /home/$USERNAME/installation_log_*.txt"
    print_info "  → /home/$USERNAME/POST_INSTALL_INFO.txt"
    if [[ "$install_hypr" == "yes" ]]; then
        print_info "  → /home/$USERNAME/HYPRLAND_KEYBINDINGS.txt"
    fi
    echo ""
    print_warning "Please unmount partitions and reboot:"
    echo "  $ umount -R /mnt"
    if [[ "$ENCRYPTION" == "yes" ]]; then
        echo "  $ cryptsetup close cryptroot"
    fi
    echo "  $ reboot"
    echo ""
    print_info "After reboot:"
    if [[ "$ENCRYPTION" == "yes" ]]; then
        echo "  1. Enter encryption password at boot"
        echo "  2. Login with username: $USERNAME"
    else
        echo "  1. Login with username: $USERNAME"
    fi
    if [[ "$install_hypr" == "yes" ]]; then
        echo "  → Type 'Hyprland' to start Hyprland"
        echo "  → Press SUPER + D for application launcher"
        echo "  → Read ~/HYPRLAND_KEYBINDINGS.txt for all shortcuts"
    fi
    echo ""
    log "Installation completed successfully at $(date)"
}

# Run main installation
main