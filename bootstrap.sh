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

# Asks which setup to apply (interactive), unless SETUP is already set.
#   ./bootstrap.sh                 -> prompts: 1) desktop  2) server
#   SETUP=server ./bootstrap.sh    -> no prompt (automation/CI)
# The answer is passed to Ansible via -e setup=... and drives the firewall
# rules, GUI/desktop packages and the Hermes desktop app.
select_setup () {
    if [ -z "${SETUP:-}" ]; then
        echo "Qual setup você quer aplicar?"
        echo "  1) desktop  - firewall bloqueia tudo por padrão, interface gráfica, apps GUI"
        echo "  2) server   - firewall aceita só via tailscale (todas as portas)"
        read -r -p "> " choice
        case "${choice:-1}" in
            1|desktop|d|D) SETUP="desktop" ;;
            2|server|s|S)  SETUP="server" ;;
            *) echo "Opção inválida: '$choice'" >&2; exit 1 ;;
        esac
    fi

    case "$SETUP" in
        desktop|server) ;;
        *) echo "SETUP inválido: '$SETUP' (use 'desktop' ou 'server')" >&2; exit 1 ;;
    esac

    echo "Setup: $SETUP"
}

run_playbook () {
    # Always run from the directory where this script lives,
    # so local.yml is found no matter where it is called from.
    cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" || exit 1
    time ansible-playbook ./local.yml -K -e "setup=$SETUP"
}

install_yay () {
    sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si && cd
}

install_yay_pkgs () {
    # GUI browsers are desktop-only
    if [ "$SETUP" = "desktop" ]; then
        yay -S zen-browser-bin helium-browser-bin --noconfirm
    fi
}

select_setup
sudo pacman -Syu
check_requirements
install_yay
install_yay_pkgs 
run_playbook

