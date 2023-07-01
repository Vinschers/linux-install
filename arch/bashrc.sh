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

setup() {
	curl -O "https://raw.githubusercontent.com/Vinschers/dotfiles/master/.config/setup/setup.sh"
    chmod +x setup.sh
    mkdir -p "$HOME/.config/setup"
    mv setup.sh "$HOME/.config/setup"
    "$HOME/.config/setup/setup.sh"
}

check "Run setup script?" 1 && setup
