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
	curl -s "https://raw.githubusercontent.com/Vinschers/dotfiles/master/.config/setup/setup.sh" | /bin/sh
}

check "Run setup script?" 1 && setup
