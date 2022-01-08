#!/bin/bash

#. ./helpers.sh 

#function check_efi_support() {
#	echo "Checking for EFI support..."
#	dir_exists "/sys/firmware/efi" \
#		&& echo "EFI Vars exists. Continuing..." \
#		|| (echo "EFI support not detected. Aborting."; exit 0)
#}

function format_partitions() {
	mkfs.ext4 /dev/sdb3
	mkswap /dev/sdb2
	mkfs.fat -F 32 /dev/sdb1
}

function mount_filesystem() {
	mount /dev/sdb3 /mnt
	mount /dev/sdb1 /mnt/boot
	swapon /dev/sdb2
}

function install_packages() {
	pacstrap /mnt base linux linux-firmware
}

function configure_system() {
	genfstab -U /mnt >> /mnt/etc/fstab
	arch-chroot /mnt
	ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
	hwclock --systohc
	locale-gen
	echo "LANG=en_US.UTF-8" > /etc/locale.conf
	echo "tower" > /etc/hostname
	mkinitcpio -P
	pacman -S intel-ucode
	passwd
}

function install_bootloader() {
	grub-install --target=x86_64 --efi-directory=esp --bootloader-id=GRUB
	grub-mkconfig -o /boot/grub/grub.cfg
}

#check_efi_support
format_partitions
mount_filesystem
install_packages
configure_system
install_bootloader
