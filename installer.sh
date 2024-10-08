#!/bin/bash

#. ./helpers.sh 

#function check_efi_support() {
#	echo "Checking for EFI support..."
#	dir_exists "/sys/firmware/efi" \
#		&& echo "EFI Vars exists. Continuing..." \
#		|| (echo "EFI support not detected. Aborting."; exit 0)
#}
function automated_partitioning() {
    local device="/dev/nvme0n1"
    local ram_size=$(grep MemTotal /proc/meminfo | awk '{print $2}') # RAM size in KB
    local swap_size=$((ram_size / 1024 / 1024 + 1)) # Convert KB to GB and add a little extra

    umount /dev/nvme0n1*
    # Clear the partition table
    wipefs -a "$device"

    # Create partitions in a single transaction
    {
        echo "label: gpt"
        echo "size=512M, type=uefi"  # Create EFI partition
        echo "size=32G, type=swap"   # Create swap partition
        echo "type=linux"            # Allocate the rest to root partition
    } | sfdisk "$device"

    # Format the partitions
    mkfs.fat -F 32 "${device}p1"  # Format EFI partition
    mkswap "${device}p2"          # Format swap partition
    mkfs.ext4 "${device}p3"       # Format root partition

    # Mount the partitions
    mount "${device}p3" /mnt
    mkdir /mnt/boot
    mount "${device}p1" /mnt/boot
    swapon "${device}p2"
}

function format_partitions() {
	mkfs.ext4 /dev/nvme0n1p3
	mkswap /dev/nvme0n1p2
	mkfs.fat -F 32 /dev/nvme0n1p1
}

function mount_filesystem() {
	mount /dev/nvme0n1p3 /mnt
	mkdir /mnt/boot
	mount /dev/nvme0n1p1 /mnt/boot
	swapon /dev/nvme0n1p2
}

function install_packages() {
	sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
	pacstrap /mnt base linux linux-firmware linux-headers
}

function configure_system() {
    genfstab -U /mnt >> /mnt/etc/fstab
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
    arch-chroot /mnt hwclock --systohc
    arch-chroot /mnt locale-gen
    arch-chroot /mnt touch /etc/locale.conf
    arch-chroot /mnt touch /etc/hostname
    arch-chroot /mnt bash -c 'sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 10/" /etc/pacman.conf'
    arch-chroot /mnt bash -c 'echo "LANG=en_US.UTF-8" > /etc/locale.conf'
    arch-chroot /mnt bash -c 'echo "tower" > /etc/hostname'
    arch-chroot /mnt bash -c "mkdir -p /etc/xdg/reflector && echo -e '--save /etc/pacman.d/mirrorlist\n--country US\n--sort rate\n--latest 5' > /etc/xdg/reflector/reflector.conf"
    arch-chroot /mnt bash -c "sed -i '/HOOKS/s/kms //' /etc/mkinitcpio.conf"
    arch-chroot /mnt mkinitcpio -P
    arch-chroot /mnt pacman -S --noconfirm amd-ucode efibootmgr grub dhcpcd sudo
    arch-chroot /mnt bash -c "echo -e '[Unit]\nDescription=Run reflector weekly to update mirrorlist\n\n[Timer]\nOnCalendar=weekly\nPersistent=true\n\n[Install]\nWantedBy=timers.target' > /etc/systemd/system/reflector.timer"
    arch-chroot /mnt systemctl enable reflector.timer
}

function install_bootloader() {
	arch-chroot /mnt grub-install --removable --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
	arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

function basic_setup() {
	arch-chroot /mnt pacman -S --noconfirm nvidia nvidia-utils nvidia-settings openssh pipewire wireplumber xorg-xinit bspwm sxhkd alacritty reflector rsync git noto-fonts xorg-xrandr xwallpaper jq vim neovim github-cli xorg-server
	arch-chroot /mnt systemctl enable dhcpcd reflector
}

function setup_nvidia() {
    echo "Setting up Nvidia..."
    # Ensure Nvidia packages are installed
    arch-chroot /mnt pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
    # Remove 'kms' hook from mkinitcpio.conf
    arch-chroot /mnt sed -i '/HOOKS/s/kms //' /etc/mkinitcpio.conf
    # Regenerate the initramfs
    arch-chroot /mnt mkinitcpio -P
    # Install and run nvidia-xconfig
    arch-chroot /mnt nvidia-xconfig
}

#check_efi_support
automated_partitioning
install_packages
configure_system
install_bootloader
basic_setup
#setup_nvidia
echo "arch-chroot /mnt and change root passwd before reboot. uncomment line at bottom of visudo command for wheel access."
echo "run useradd -m -g wheel obbie the run passwd obbie to give yourself a password."
