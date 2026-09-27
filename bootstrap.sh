#!/bin/bash
check_requirements () {
    if ! command -v ansible &> /dev/null
    then
        sudo pacman -S --needed ansible ansible-core --noconfirm
    fi

    if ! command -v git &> /dev/null
    then
        sudo pacman -S --needed git --noconfirm
    fi

    if ! command -v fakeroot &> /dev/null
    then
        sudo pacman -S --needed fakeroot --noconfirm
    fi
    
}

run_playbook () {
    # Always run from the directory where this script lives,
    # so local.yml is found no matter where it is called from.
    cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" || exit 1
    time ansible-playbook ./local.yml -K
}

install_yay () {
    sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si && cd
}

install_yay_pkgs () {
    yay -S zen-browser-bin helium-browser-bin --noconfirm
}

sudo pacman -Syu
check_requirements
install_yay
install_yay_pkgs 
run_playbook

