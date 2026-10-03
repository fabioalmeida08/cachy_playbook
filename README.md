# Cachy Playbook

Personal Ansible playbook for installing and configuring Arch Linux.

## Overview

This playbook automates the setup of an Arch Linux workstation, including:

- **Setup profiles**: `desktop` (GUI) or `server` (headless), chosen interactively by `bootstrap.sh`
- **Development tools**: git, neovim, tmux, zsh, docker, and more
- **AI agents**: Hermes Agent (CLI + desktop app on `desktop`), installed with the
  official installer script, and OpenCode — both setups
- **System utilities**: fonts, themes, bluetooth, audio, and networking
- **Graphics drivers**: Intel (mesa) and NVIDIA through `chwd`, the same hardware detection the CachyOS graphical installer uses (explicit `nvidia-dkms-580xx` profile when the chip is in `nvidia-580.ids`) — `desktop` only
- **Desktop environment**: niri (Wayland compositor) with XDG portals, XWayland bridge, clipboard and keyring — `desktop` only
- **Desktop shell**: Noctalia v4 (Quickshell) — `desktop` only
- **Login screen**: ly (TUI display manager) with the matrix animation — the
  dotfiles config is mirrored into `/etc/ly/config.ini` (the DM runs as root
  and never reads `~/.config/ly`) — `desktop` only
- **Gaming**: Steam, Gamemode, ProtonUp-QT (Proton-GE) — `desktop` only
- **Multimedia**: mpv, qBittorrent, calibre (e-book manager) — `desktop` only (Zen Browser comes from `bootstrap.sh`)
- **Firewall**: ufw with `deny incoming` on both setups; `server` additionally allows SSH (22/tcp) from the LAN over IPv4, all traffic from the `tailscale0` interface (plus udp 41641 and routed tailnet traffic)
- **VPN**: Tailscale on both setups
- **Dotfiles**: managed via GNU Stow

## Setup profiles

The `setup` variable (`desktop` | `server`) gates the firewall rules, GUI
packages and the Hermes desktop app.

| | `desktop` | `server` |
|---|---|---|
| Firewall | deny incoming, no extra rules | deny incoming + SSH 22/tcp from `lan_subnet` (IPv4), all traffic from `tailscale0`, udp 41641, routed |
| GUI packages (niri, fonts, themes, steam, …) | yes | no |
| Graphics drivers (Intel mesa + NVIDIA via `chwd`) | yes | no |
| OpenSSH | client only (git/ssh) | client + `sshd` enabled and started |
| Hermes Agent CLI | yes | yes |
| Hermes desktop app | yes | no |
| Hermes dashboard (`9119`, tailnet only) | no | yes |
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
  reconnect — use a physical console. On `server`, the playbook also enables
  and starts `sshd`, and SSH stays reachable through `tailscale0` once
  Tailscale is logged in, plus from the LAN.
- **The server's SSH rule is IPv4-only and LAN-scoped.** `lan_subnet` defaults
  to the network behind the default IPv4 route (e.g. `192.168.1.0/24`). Because
  the source is an IPv4 CIDR, ufw writes it to `user.rules` only — no ip6tables
  counterpart, so IPv6 stays fully denied. If the SSH client is on a different
  network, override it:

  ```bash
  ansible-playbook local.yml -K -e setup=server -e lan_subnet=10.20.30.0/24
  # or
  LAN_SUBNET=10.20.30.0/24 ./bootstrap.sh
  ```
- **Docker published ports bypass ufw.** Containers mapping ports to
  `0.0.0.0` (`-p 8080:80`) go through the `DOCKER` chain, not ufw rules.
  On `server`, harden this with `DOCKER-USER` rules if services must only be
  reachable from the tailnet.

## Hermes dashboard (server only)

The playbook creates and enables `hermes-dashboard.service`
(`roles/arch/templates/hermes-dashboard.service.j2` →
`/etc/systemd/system/hermes-dashboard.service`), whose `ExecStart` calls the
start wrapper (`roles/arch/templates/hermes-dashboard.sh.j2` →
`/usr/lib/hermes-dashboard/start.sh`):

```bash
#!/bin/sh
IP=$(/usr/bin/tailscale ip -4) || exit 1
[ -n "$IP" ] || exit 1
exec ~/.local/bin/hermes dashboard --host "$IP" --port 9119 --no-open
```

The wrapper exists because **systemd has no command substitution**: a
`$(tailscale ip -4)` written directly in `ExecStart` is erased as an invalid
variable, `--host` ends up without a value and the service dies with exit 2
on every boot. The shell in the wrapper resolves the IP at every start, so
nothing is hardcoded and a changed IP is picked up on the next restart.

The bind is the machine's Tailscale IPv4, so the dashboard is reachable only
from the tailnet — the `allow in on tailscale0` rule already covers port 9119,
no extra firewall task. `EnvironmentFile` loads `~/.hermes/.env` (API keys)
into the process; `Restart=always` + `RestartSec=10` bring it back after
crashes and reboots.

**The playbook never touches credentials.** A non-loopback bind engages the
dashboard's auth gate and the process *refuses to start* without a configured
user/password (fail-closed), and under systemd there is no interactive prompt
to create one. So the playbook writes the unit, enables it at boot, and only
starts the service if a credential already exists — otherwise it prints the
steps below:

```bash
# 1. log into the tailnet — the wrapper refuses to start without an IP
tailscale up

# 2. pick the model / API key (interactive)
hermes setup

# 3. create the dashboard credential (also interactive)
hermes dashboard --host "$(tailscale ip -4)" --port 9119
#    → no credential yet, so it offers to create username/password
#    → choose them (writes dashboard.basic_auth to ~/.hermes/config.yaml)
#    → Ctrl+C

# 4. start it — any of these works
sudo systemctl start hermes-dashboard
# or reboot (enabled=yes covers the boot)
# or re-run the playbook (the credential check now passes)
```

Verify from any machine on the tailnet:

```bash
curl -s http://<server-ts-ip>:9119/api/status | jq '.auth_required, .auth_providers'
# true
# ["basic"]
```

**Connecting from the client:**

- Browser: `http://<server-ts-ip>:9119` → log in with the username/password.
- Hermes Desktop: Settings → Gateways → **Remote gateway** → Remote URL
  (`http://<server-ts-ip>:9119`) → Sign in. Sign in once; the app reuses the
  session for the chat WebSocket.

**If you rebooted before creating the credential** — or with the node logged
out of tailscale, which makes the wrapper exit without an IP — the unit stops
in `failed` after 5 attempts (`StartLimitBurst`), so the journal stays clean.
The start-limit counter lives in RAM, so the next reboot starts fresh —
otherwise fix the cause (`tailscale up` / credential) and reset by hand:

```bash
sudo systemctl reset-failed hermes-dashboard
sudo systemctl start hermes-dashboard
```

Logs: `journalctl -u hermes-dashboard -f`.

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
│       ├── templates/       # Jinja2 templates (systemd units)
│       └── tasks/           # Task definitions
│           ├── desktop_env/ # Desktop environment configs
│           └── software/    # Package installation
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
| `nvidia` | NVIDIA drivers via `chwd` (only on `setup=desktop`) |
| `desktop` | Desktop environment (only on `setup=desktop`) |
| `dotfiles` | Dotfiles management |
| `fonts` | Font installation |
| `network` | Network tools |
| `firewall` | ufw rules |
| `ufw` | ufw rules |
| `tailscale` | Tailscale + its firewall rules |
| `hermes` | Hermes Agent (CLI + desktop app) and, on `server`, the dashboard service |
| `opencode` | OpenCode coding agent (CLI) |
| `ssh` | OpenSSH client; on `server` also starts `sshd` + its LAN firewall rule |

## License

MIT
