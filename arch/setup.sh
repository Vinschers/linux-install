#!/bin/sh

espaco() {
	printf "\n\n\n\n" >&2
}

check() {
	if [ "$2" = "1" ]; then
		printf "%s [Y/n] " "$1" >&2
		read -r ans

		[ "$ans" = "" ] || [ "$ans" = "Y" ] || [ "$ans" = "y" ]
	else
		printf "%s [y/N] " "$1" >&2
		read -r ans

		! [ "$ans" = "" ] || [ "$ans" = "N" ] || [ "$ans" = "n" ]
	fi
}

setup_vb() {
	pacman -S --noconfirm virtualbox-guest-utils
	systemctl enable vboxservice
}

setup_time_zone() {
	ln -sf /usr/share/zoneinfo/Brazil/East /etc/localtime
	hwclock --systohc
}

setup_network() {
	pacman -S --noconfirm networkmanager
	systemctl enable NetworkManager

	echo "$1" >/etc/hostname

	echo -e "127.0.0.1        localhost\n" >/etc/hosts
	echo -e "::1              localhost\n" >>/etc/hosts
	echo -e "127.0.1.1        $1.localdomain  $1" >>/etc/hosts
}

setup_grub() {
	main_partition="$1"

	[ -n "$main_partition" ] && sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=$main_partition:main root=/dev/mapper/main-root /g" /etc/default/grub

	echo "Setting up grub menu..."

	pacman -S --noconfirm efibootmgr dosfstools os-prober mtools
	grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck

	echo "GRUB_DISABLE_OS_PROBER=false" >>/etc/default/grub

	pacman -S --noconfirm ntfs-3g
	grub-mkconfig -o /boot/grub/grub.cfg
}

setup_locale() {
	mv ./locale.gen /etc/locale.gen
	locale-gen
	echo "LANG=en_US.UTF-8" >/etc/locale.conf
}

create_new_user() {
	useradd -mg wheel $user_name
	passwd $user_name

	mv /home/$user_name/.bashrc /home/$user_name/.bashrc.old
	cp ./bashrc.sh /home/$user_name/.bashrc
}

change_mkinitcpio() {
	default_modules="$(grep "^MODULES=" /etc/mkinitcpio.conf)"
	modified_modules="${default_modules%?} ext4)"
	modified_modules="$(echo "$modified_modules" | sed 's/( /(/g')"

	sed -i "s/^$default_modules/$modified_modules/g" /etc/mkinitcpio.conf

	default_hooks="$(grep "^HOOKS=" /etc/mkinitcpio.conf)"
	modified_hooks="${default_hooks%?} encrypt lvm2)"
	modified_hooks="$(echo "$modified_hooks" | sed 's/( /(/g')"

	sed -i "s/^$default_hooks/$modified_hooks/g" /etc/mkinitcpio.conf

	mkinitcpio -p linux
}

debug="$1"
main_partition="$2"
hostname="$3"
user_name="$4"
vm="$5"

$vm && setup_vb
espaco

! $debug || check "Setup localtime?" 1 && setup_time_zone
espaco

! $debug || check "Setup locale?" 1 && setup_locale
espaco

! $debug || check "Setup Network configuration?" 1 && setup_network "$hostname"
espaco

! $debug || check "Change root password?" 1 && passwd
espaco

! $debug || check "Update sudoers file?" 1 && cat ./sudoers >/etc/sudoers
espaco

! $debug || check "Create new user?" 1 && create_new_user
espaco

! $debug || check "Install and setup grub?" 1 && setup_grub "$main_partition"
espaco

[ -n "$main_partition" ] && change_mkinitcpio
