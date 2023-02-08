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

set_time() {
	timedatectl set-ntp true
}

fdisk_nonencrypt_cmds () {
    total_ram="$(free --giga | awk '/^Mem:/{print $2}')GB"

    echo "g"            # Clear new GPT partition table

    echo "n"            # Create new partition
    echo "1"            # Partition number 1
    echo ""             # Default: start at the beginning of disk
    echo "+512M"        # 512 MiB boot partition
    echo "t"            # Change partition type
    echo "1"            # EFI partition

    echo "n"            # Create new partition
    echo "2"            # Partition number 2
    echo ""             # Default: start immediately after preceding partition
    echo "+$total_ram"  # Swap the size of total RAM available
    echo "t"            # Change partition type
    echo "19"           # Swap partition

    echo "n"            # Create new partition
    echo "3"            # Partition number 3
    echo ""             # Default: start immediately after preceding partition
    echo ""             # Default: extend partition to end of disk

    echo "p"            # Print the in-memory partition table
    echo "w"            # Write partition table
}

fdisk_encrypt_cmds () {
    echo "g"            # Clear new GPT partition table

    echo "n"            # Create new partition
    echo "1"            # Partition number 1
    echo ""             # Default: start at the beginning of disk
    echo "+512M"        # 512 MiB boot partition
    echo "t"            # Change partition type
    echo "1"            # EFI partition

    echo "n"            # Create new partition
    echo "2"            # Partition number 2
    echo ""             # Default: start immediately after preceding partition
    echo ""             # Default: extend partition to end of disk

    echo "p"            # Print the in-memory partition table
    echo "w"            # Write partition table
}

encrypt_disk () {
    main_partition="$1"
    total_ram="$(free --giga | awk '/^Mem:/{print $2}')GB"
    [ "$total_ram" = "0GB" ] && total_ram="1GB"

    modprobe dm-crypt

    cryptsetup -vy luksFormat --type luks2 "$main_partition"
    cryptsetup luksOpen "$main_partition" lvm

    pvcreate /dev/mapper/lvm
    vgcreate main /dev/mapper/lvm


    lvcreate -L "$total_ram" -n swap main
    lvcreate -l 100%FREE -n root main
}

create_fs () {
    boot_partition="$1"
    swap_partition="$2"
    root_partition="$3"

    mkfs.fat -F32 -n BOOT "$boot_partition"
    mkswap -L swap "$swap_partition"
    mkfs.ext4 -L root "$root_partition"
}

mount_partitions () {
    boot_partition="$1"
    swap_partition="$2"
    root_partition="$3"

    mount "$root_partition" /mnt
    mount -m "$boot_partition" /mnt/boot
    swapon -L swap
}

run_pacstrap() {
    processor="$1"
    encrypt=$2

	sudo pacman --noconfirm -Sy archlinux-keyring

    if $encrypt; then
	    pacstrap /mnt base base-devel linux linux-firmware vim git lsb-release accountsservice grub "$processor-ucode" mkinitcpio lvm2
    else
	    pacstrap /mnt base base-devel linux linux-firmware vim git lsb-release accountsservice grub "$processor-ucode"
    fi
}

create_fstab() {
	genfstab -U /mnt >>/mnt/etc/fstab
}

setup_arch() {
	git clone https://github.com/Vinschers/linux-install.git
	chmod -R 777 linux-install/
	cd linux-install/arch/ || exit 1

	printf 'Starting setup...\n\n\n' && ./setup.sh "$1" "$2" "$3" "$4" "$5"
}


printf "Processor (intel/amd): "
read -r processor

check "Debug mode?" 0 && debug=true || debug=false

check "VirtualBox environment?" 0 && vm=true || vm=false

printf "Hostname: "
read -r hostname

printf "User name: "
read -r user_name

encrypt=false

if check "Create partitions?" 1; then
    printf "Device: "
    read -r device

    if check "Encrypt disk" 1; then
        fdisk_encrypt_cmds | fdisk "$device"

        sleep 1

        boot_partition="/dev/$(lsblk -o KNAME -n "$device" | sed -n '2p')"
        main_partition="/dev/$(lsblk -o KNAME -n "$device" | sed -n '3p')"

        encrypt_disk "$main_partition"

        swap_partition="/dev/mapper/main-swap"
        root_partition="/dev/mapper/main-root"

        encrypt=true
    else
        fdisk_nonencrypt_cmds | fdisk "$device"

        boot_partition="$(lsblk -o KNAME -n "$device" | sed -n '2p')"
        swap_partition="$(lsblk -o KNAME -n "$device" | sed -n '3p')"
        root_partition="$(lsblk -o KNAME -n "$device" | sed -n '4p')"
    fi
else
    printf "Boot partition: "
    read -r boot_partition

    printf "Swap partition: "
    read -r swap_partition

    printf "Root partition: "
    read -r root_partition
fi
espaco


! $debug || check "Create filesystems" 1 && create_fs "$boot_partition" "$swap_partition" "$root_partition"
espaco


! $debug || check "Mount partitions" 1 && mount_partitions "$boot_partition" "$swap_partition" "$root_partition"
espaco


! $debug || check "Setup time?" 1 && set_time
espaco


! $debug || check "Run pacstrap command?" 1 && run_pacstrap "$processor" $encrypt
espaco

! $debug || check "Create fstab file?" 1 && create_fstab
espaco

export -f setup_arch
! $debug || check "Clone full repository and run arch setup?" 1 && arch-chroot /mnt /bin/sh -c "setup_arch '$debug' '$main_partition' '$hostname' '$user_name' '$vm'"
espaco

echo "Reboot the computer and remove the installation media."
