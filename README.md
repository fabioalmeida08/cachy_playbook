# Cachy Playbook

Personal Ansible playbook for installing and configuring Arch Linux.

## Overview

This playbook automates the setup of an Arch Linux workstation, including:

- **Development tools**: git, neovim, tmux, zsh, docker, and more
- **System utilities**: fonts, themes, bluetooth, audio, and networking
- **Desktop environment**: niri (Wayland compositor)
- **Gaming**: Steam, Lutris, Gamemode, Proton-GE
- **Multimedia**: mpv, qBittorrent, Firefox, Brave, Zen Browser
- **Dotfiles**: managed via GNU Stow

## Requirements

- Arch Linux (or Arch-based distribution)
- Ansible
- Git
- Vagrant (optional, for testing)

## Usage

### Quick Start

```bash
# Clone the repository
git clone https://github.com/fabioalmeida08/cachy_playbook.git
cd cachy_playbook

# Run the bootstrap script
./bootstrap.sh
```

### Manual Run

```bash
# Install dependencies
sudo pacman -S --needed ansible git

# Run the playbook
ansible-playbook local.yml -K
```

### With Vagrant

```bash
vagrant up
vagrant provision
```

## Project Structure

```
cachy_playbook/
├── roles/
│   └── arch/
│       ├── handlers/        # Handlers for service management
│       └── tasks/           # Task definitions
│           ├── desktop_env/ # Desktop environment configs
│           ├── dotfiles/    # Dotfiles management
│           ├── software/    # Package installation
│           └── system_setup/# System configuration
├── local.yml                # Main playbook
├── Vagrantfile              # Vagrant configuration
└── bootstrap.sh             # Bootstrap script
```

## Naming Convention

All tasks follow the format: `category | component | action`

**Categories:**
- `software` - Package installation/removal
- `service` - Service management
- `config` - File/system configuration
- `desktop` - Desktop environment
- `fonts` - Font management
- `group` - Group management
- `drivers` - Driver installation
- `network` - Network tools

**Actions:**
- `install` - Install package
- `remove` - Remove package
- `enable` - Enable service
- `disable` - Disable service
- `start` - Start service
- `stop` - Stop service
- `restart` - Restart service
- `configure` - Configure
- `generate` - Generate
- `add` - Add
- `create` - Create
- `set` - Set
- `build` - Build
- `clone` - Clone

## Tags

| Tag | Description |
|-----|-------------|
| `packages` | Install packages |
| `config` | Configuration tasks |
| `service` | Service management |
| `drivers` | Graphics drivers |
| `desktop` | Desktop environment |
| `dotfiles` | Dotfiles management |
| `fonts` | Font installation |
| `network` | Network tools |

## License

MIT
