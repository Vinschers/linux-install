#!/bin/bash

printf "Run setup script? [Y/n]"
read -r setup

if [ "$setup" = "" ] || [ "$setup" = "Y" ] || [ "$setup" = "y" ]; then
    curl -sSL https://raw.githubusercontent.com/Vinschers/dotfiles/master/.config/setup/setup.sh | sh
fi
