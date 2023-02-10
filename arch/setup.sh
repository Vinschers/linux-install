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

setup_locale() {
    sed -i "s|#pt_BR.UTF-8 UTF-8|pt_BR.UTF-8 UTF-8|g" /etc/locale.gen
    sed -i "s|#pt_BR ISO-8859-1|pt_BR ISO-8859-1|g" /etc/locale.gen
    sed -i "s|#en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|g" /etc/locale.gen
    sed -i "s|#en_US ISO-8859-1|en_US ISO-8859-1|g" /etc/locale.gen

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
	sed -i "s/block filesystems/block encrypt lvm2 filesystems/" /etc/mkinitcpio.conf

	# mkdir /root/secrets && chmod 700 /root/secrets
	# head -c 64 /dev/urandom >/root/secrets/crypto_keyfile.bin && chmod 600 /root/secrets/crypto_keyfile.bin
	# cryptsetup -v luksAddKey -i 1 "$main_partition" /root/secrets/crypto_keyfile.bin
	#
	# default_files="$(grep "^FILES=" /etc/mkinitcpio.conf)"
	# modified_files="${default_files%?} /root/secrets/crypto_keyfile.bin)"
	# modified_files="$(echo "$modified_files" | sed 's/( /(/g')"
	#
	# sed -i "s|^$default_files|$modified_files|g" /etc/mkinitcpio.conf

	mkinitcpio -p linux
}

setup_grub() {
	main_partition="$1"
	root_partition="$2"
	swap_partition="$3"

	uuid="$(blkid -o value -s UUID "$main_partition")"
    kernel_arguments="cryptdevice=$main_partition:main root=$root_partition resume=$swap_partition cryptkey=rootfs:/root/secrets/crypto_keyfile.bin"

	[ -n "$main_partition" ] && sed -i "s/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/g" /etc/default/grub
	# [ -n "$main_partition" ] && sed -i "s/^#GRUB_ENABLE_CRYPTODISK=y/GRUB_ENABLE_CRYPTODISK=y/g" /etc/default/grub
	[ -n "$main_partition" ] && sed -i "s|^GRUB_CMDLINE_LINUX=\"|GRUB_CMDLINE_LINUX=\"$kernel_arguments|g" /etc/default/grub

	echo "Setting up grub menu..."

	pacman -S --noconfirm efibootmgr dosfstools os-prober mtools ntfs-3g

	grub-install --target=x86_64-efi --bootloader-id=grub --recheck --efi-directory=/boot/efi
	grub-mkconfig -o /boot/grub/grub.cfg
}

install_extra() {
	pacman -S --noconfirm archlinux-keyring lsb-release
}

debug="$1"
main_partition="$2"
root_partition="$3"
swap_partition="$4"
hostname="$5"
user_name="$6"
vm="$7"

$vm && setup_vb
espaco

! $debug || check "Setup localtime?" 1 && setup_time_zone
espaco

! $debug || check "Setup locale?" 1 && setup_locale
espaco

! $debug || check "Setup Network configuration?" 1 && setup_network "$hostname"
espaco

! $debug || check "Update sudoers file?" 1 && sed -i "s|^# %wheel ALL=(ALL) ALL|%wheel ALL=(ALL) ALL|g" /etc/sudoers
espaco

if [ -n "$main_partition" ]; then
	! $debug || check "Change mkinitcpio?" 1 && change_mkinitcpio
	espaco
fi

! $debug || check "Install and setup grub?" 1 && setup_grub "$main_partition" "$root_partition" "$swap_partition"
espaco

! $debug || check "Change root password?" 1 && passwd
espaco

! $debug || check "Create new user?" 1 && create_new_user
espaco

! $debug || check "Install extra packages?" 1 && install_extra
