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

install_yay () {
    git clone https://aur.archlinux.org/yay.git
    cd yay/
    makepkg -si
    cd ..
    rm -rf yay/
}

download_dotfiles () {
	git clone --bare https://github.com/Vinschers/dotfiles.git $HOME/.dotfiles-git
	git --git-dir=$HOME/.dotfiles-git/ --work-tree=$HOME checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} rm $HOME/{}
	git --git-dir=$HOME/.dotfiles-git/ --work-tree=$HOME checkout
	git --git-dir=$HOME/.dotfiles-git/ --work-tree=$HOME config --local status.showUntrackedFiles no

	check "Run setup script?" 1 && $HOME/.local/scripts/setup/setup.sh

    rm ~/.bash_profile
}

check "Install yay?" 1 && install_yay

check "Download dotfiles?" 1 && download_dotfiles
