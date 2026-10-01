# Cachy Playbook

Personal Ansible playbook for installing and configuring Arch Linux.

## Overview

This playbook automates the setup of an Arch Linux workstation, including:

- **Setup profiles**: `desktop` (GUI) or `server` (headless), chosen interactively by `bootstrap.sh`
- **Development tools**: git, neovim, tmux, zsh, docker, and more
- **AI agent**: Hermes Agent (CLI + desktop app on `desktop`)
- **System utilities**: fonts, themes, bluetooth, audio, and networking
- **Desktop environment**: niri (Wayland compositor) with XDG portals, XWayland bridge, clipboard and keyring — `desktop` only
- **Desktop shell**: Noctalia v4 (Quickshell) — `desktop` only
- **Gaming**: Steam, Lutris, Gamemode, ProtonUp-QT (Proton-GE) — `desktop` only
- **Multimedia**: mpv, qBittorrent, Firefox, Brave, Zen Browser — `desktop` only
- **Firewall**: ufw with `deny incoming` on both setups; `server` additionally allows all traffic from the `tailscale0` interface (plus udp 41641 and routed tailnet traffic)
- **VPN**: Tailscale on both setups
- **Dotfiles**: managed via GNU Stow

## Setup profiles

The `setup` variable (`desktop` | `server`) gates the firewall rules, GUI
packages and the Hermes desktop app.

| | `desktop` | `server` |
|---|---|---|
| Firewall | deny incoming, no extra rules | deny incoming + all traffic from `tailscale0`, udp 41641, routed |
| GUI packages (niri, fonts, themes, steam, …) | yes | no |
| Hermes Agent CLI | yes | yes |
| Hermes desktop app | yes | no |
| Tailscale | yes | yes |

`bootstrap.sh` asks for the profile before doing anything. For
non-interactive runs, export `SETUP` (the prompt is skipped):

```bash
SETUP=server ./bootstrap.sh
```

Calling `ansible-playbook` directly works too — it defaults to `desktop`
unless you pass the variable:

```bash
SETUP=server ansible-playbook local.yml -K
# or
ansible-playbook local.yml -K -e setup=server
```

## Firewall caveats

- **`desktop` blocks everything, including SSH.** There is no `ufw allow` rule
  on purpose. If you run the playbook over SSH on a desktop setup, your
  session drops when the firewall is enabled and you won't be able to
  reconnect — use a physical console. On `server`, SSH stays reachable
  through `tailscale0` once Tailscale is logged in.
- **Docker published ports bypass ufw.** Containers mapping ports to
  `0.0.0.0` (`-p 8080:80`) go through the `DOCKER` chain, not ufw rules.
  On `server`, harden this with `DOCKER-USER` rules if services must only be
  reachable from the tailnet.

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

# Run the bootstrap script (asks for desktop/server first)
./bootstrap.sh
```

### Manual Run

```bash
# Install dependencies
sudo pacman -S --needed ansible git

# Run the playbook (defaults to desktop)
ansible-playbook local.yml -K

# Run it for a server
ansible-playbook local.yml -K -e setup=server
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
| `desktop` | Desktop environment (only on `setup=desktop`) |
| `dotfiles` | Dotfiles management |
| `fonts` | Font installation |
| `network` | Network tools |
| `firewall` | ufw rules |
| `ufw` | ufw rules |
| `tailscale` | Tailscale + its firewall rules |
| `hermes` | Hermes Agent (CLI + desktop) |

## License

MIT
