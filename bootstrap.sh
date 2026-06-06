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
    cd arch_playbook
    time ansible-playbook local.yml -K
}

install_yay () {
    sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si && cd
}

install_yay_pkgs () {
    yay -S zen-browser-bin code --noconfirm
}

sudo pacman -Syu
check_requirements
install_yay
install_yay_pkgs 
run_playbook

