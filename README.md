# Linux installation scripts
## Summary
This repository contains the scripts I did to automatically install Linux distributions I've used (only Arch currently)

All configurations, dotfiles, themes and things that are usually set up after a base installation are located in my [dotfiles bare repository](https://github.com/Vinschers/dotfiles).

## Usage
Before using any script, the creation and setup of a partition table must be done manually as well as mounting the root (/) partition to /mnt.
This is done using `cfdisk` or any other tool you are more familiar with. Suppose the partitions /dev/sda1, /dev/sda2 and /dev/sda3 are
created for boot, swap and root (/) respectively. In this case, you would run
```
mkfs.fat -F32 /dev/sda1
mkswap /dev/sda2
mkfs.ext4 /dev/sda3

swapon /dev/sda2
mount /dev/sda3 /mnt
```
Once the partition
table is created and the drivers are mounted, just download the script of your choice and change its permissions so that you can run it.

### Arch example
```
curl -O https://raw.githubusercontent.com/Vinschers/linux-install/master/arch.sh
chmod +x arch.sh
./arch.sh
```
