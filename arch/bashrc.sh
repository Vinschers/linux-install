#!/bin/bash

printf "Run setup script? [Y/n] "
read -r setup

if [ "$setup" = "" ] || [ "$setup" = "Y" ] || [ "$setup" = "y" ]; then
    curl -O https://raw.githubusercontent.com/Vinschers/dotfiles/master/.config/setup/setup.sh
    ./setup.sh
    rm -f ./setup.sh
fi
