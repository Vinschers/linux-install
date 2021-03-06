#!/bin/sh

espaco () {
    echo -e "\n\n\n" >&2
}

check () {
    if [ "$2" == "1" ]
    then
        echo -n "$1 [Y/n] " >&2
        read ans

        [ "$ans" == "" ] || [ "$ans" == "Y" ] || [ "$ans" == "y" ]
    else
        echo -n "$1 [y/N] " >&2
        read ans

        ! [ "$ans" == "" ] || [ "$ans" == "N" ] || [ "$ans" == "n" ]
    fi
}

setup_vb () {
    pacman -S --noconfirm virtualbox-guest-utils
    ln -s /etc/runit/sv/vboxservice /etc/runit/runsvdir/default
}

setup_network () {
    pacman -S --noconfirm networkmanager networkmanager-runit connman-runit

    echo "$1" > /etc/hostname

    echo -e "127.0.0.1        localhost\n" > /etc/hosts
    echo -e "::1              localhost\n" >> /etc/hosts
    echo -e "127.0.1.1        $1.localdomain  $1" >> /etc/hosts

    ln -s /etc/runit/sv/connmand /etc/runit/runsvdir/default
}

setup_grub () {
    pacman -S --noconfirm grub parted
    espaco
    echo "Setting up grub menu..."

    boot_partition=$1

    device=$(lsblk -no pkname $boot_partition)
    device="/dev/$device"

    partition_label=$(parted $device print | grep -i "Partition Table")
    partition_label=${partition_label##* }

    if [ "$partition_label" == "gpt" ]
    then
        mkdir -p /boot/EFI
        mount $boot_partition /boot/EFI

        pacman -S --noconfirm efibootmgr dosfstools os-prober mtools
        grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
    elif [ "$partition_label" == "msdos" ]
    then
        mount $boot_partition /boot
        grub-install $device
    fi

    pacman -S --noconfirm ntfs-3g
    grub-mkconfig -o /boot/grub/grub.cfg
}

setup_locale () {
    mv ./locale.gen /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
}

create_new_user () {
    echo -n "User name: "
    read user_name

    useradd -mg wheel $user_name
    passwd $user_name

    mv /home/$user_name/.bashrc /home/$user_name/.bashrc.old
    cp ./install-yay /home/$user_name/.bashrc
}

debug=$1
boot_partition=$2
hostname=$3


check "VirtualBox environment?" 0 && setup_vb ; espaco

setup_time_zone () {
    ln -sf /usr/share/zoneinfo/Brazil/East /etc/localtime
    hwclock --systohc
}

! $debug || check "Setup localtime?" 1 && setup_time_zone ; espaco

! $debug || check "Setup locale?" 1 && setup_locale ; espaco

! $debug || check "Setup Network configuration?" 1 && setup_network "$hostname" ; espaco

! $debug || check "Install and setup grub?" 1 && setup_grub $boot_partition ; espaco

! $debug || check "Change root password?" 1 && passwd ; espaco

! $debug || check "Update sudoers file?" 1 && cat ./sudoers > /etc/sudoers ; espaco

! $debug || check "Create new user?" 1 && create_new_user ; espaco