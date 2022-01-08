#!/bin/bash

#. ./helpers.sh 

#function check_efi_support() {
#	echo "Checking for EFI support..."
#	dir_exists "/sys/firmware/efi" \
#		&& echo "EFI Vars exists. Continuing..." \
#		|| (echo "EFI support not detected. Aborting."; exit 0)
#}

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
	pacstrap /mnt base linux linux-firmware
}

function configure_system() {
	genfstab -U /mnt >> /mnt/etc/fstab
	arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
	arch-chroot /mnt hwclock --systohc
	arch-chroot /mnt locale-gen
	arch-chroot /mnt echo "LANG=en_US.UTF-8" > /etc/locale.conf
	arch-chroot /mnt echo "tower" > /etc/hostname
	arch-chroot /mnt mkinitcpio -P
	arch-chroot /mnt pacman -S intel-ucode efibootmgr grub
}

function install_bootloader() {
	arch-chroot /mnt grub-install --removable --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
	arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

set -e
main "$@"
set +e

#check_efi_support
format_partitions
mount_filesystem
install_packages
configure_system
install_bootloader
