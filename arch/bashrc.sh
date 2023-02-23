#!/bin/bash

check() {
	if [ "$2" == "1" ]; then
		echo -n "$1 [Y/n] " >&2
		read ans

		[ "$ans" == "" ] || [ "$ans" == "Y" ] || [ "$ans" == "y" ]
	else
		echo -n "$1 [y/N] " >&2
		read ans

		! [ "$ans" == "" ] || [ "$ans" == "N" ] || [ "$ans" == "n" ]
	fi
}

install_yay() {
	git clone https://aur.archlinux.org/yay.git
	cd yay/ || exit 1
	makepkg -si
	cd ..
	rm -rf yay/
}

download_dotfiles() {
    mkdir -p "$HOME/.config/dotfiles"
	git clone --bare git@github.com:Vinschers/dotfiles.git "$HOME/.config/dotfiles/.dotfiles-git"
	git --git-dir="$HOME/.config/dotfiles/.dotfiles-git/" --work-tree="$HOME" checkout 2>&1 | grep -E "\s+\." | awk '{print $1}' | xargs -I{} rm "$HOME/{}"
	git --git-dir="$HOME/.config/dotfiles/.dotfiles-git/" --work-tree="$HOME" checkout
	git --git-dir="$HOME/.config/dotfiles/.dotfiles-git/" --work-tree="$HOME" config --local status.showUntrackedFiles no

	rm "$HOME/.bash_profile" "$HOME/.bashrc.old"

	source "$HOME/.profile"
	check "Run setup script?" 1 && "$SCRIPTS_DIR/setup/setup.sh" && rm -f "$HOME/.bashrc"
}

check "Install yay?" 1 && install_yay

check "Download dotfiles?" 1 && download_dotfiles
