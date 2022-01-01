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

set_time () {
    timedatectl set-ntp true
}

run_pacstrap () {
    pacstrap /mnt base base-devel linux linux-firmware vim git
}

create_fstab () {
    genfstab -U /mnt >> /mnt/etc/fstab
}

setup_arch () {
    git clone https://github.com/Vinschers/linux-install.git
    chmod -R 777 linux-install/
    cd linux-install/arch/

    echo -e 'Starting setup...\n\n' &&
    ./setup.sh $1 $2 $3
}

check "Debug mode?" 0 && debug=true || debug=false

echo -n "Boot partition: "
read boot_partition

echo -n "Hostname: "
read hostname

! $debug || check "Setup time?" 1 && set_time ; espaco

! $debug || check "Run pacstrap command?" 1 && run_pacstrap ; espaco

! $debug || check "Create fstab file?" 1 && create_fstab ; espaco

export -f setup_arch
! $debug || check "Clone full repository and run arch setup?" 1 && arch-chroot /mnt /bin/sh -c "setup_arch $debug $boot_partition $hostname"; espaco

echo "Reboot the computer and remove the installation media."
