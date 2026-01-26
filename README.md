# nixpille

Don't touch my files! I hate when programs modify files I don't control, data is data and code is code. Config is a weird middle ground that should be managed or disappear.

## Quick Start

```sh
# 1. First-time setup on a new machine
secrets login            # Authenticate with Bitwarden
secrets pull             # Pull all secrets (SSH, GPG, configs)

# 2. Rebuild NixOS
task switch HOST=<hostname>
```

## Secrets Architecture

```
Bitwarden (encrypted, synced)
    |
    | secrets pull
    v
GNOME Keyring (local, encrypted)
    |
    | login (systemd service)
    v
tmpfs (ephemeral, plaintext)
    |
    | sops-nix decrypts
    v
/run/user/<uid>/* (never on disk)
```

**Security model:**
- Identity secrets (SSH keys, GPG keys, configs) live in Bitwarden
- Rotatable secrets (API tokens) are in sops-encrypted `secrets.yaml`
- Everything decrypts to tmpfs - plaintext never touches disk
- GNOME Keyring caches secrets locally (keyring-locked when logged out)
- Age key for sops-nix is stored in keyring, exported on login

## Commands

```sh
# NixOS
task switch              # Rebuild NixOS config
task hm                  # Rebuild home-manager config
task test                # Test in VM
task check               # Validate flake
task fmt                 # Format nix files

# Secrets CLI
secrets pull             # Pull all from Bitwarden
secrets status           # Show what's loaded
secrets login            # Login/unlock Bitwarden
secrets lock             # Clear all secrets from memory
secrets export           # Export from keyring (offline)
secrets sync             # Sync local files back to Bitwarden

# Secret types
secrets ssh pull         # SSH keys -> ssh-agent
secrets gpg pull         # GPG keys -> gpg keyring
secrets files pull       # Config files -> keyring + tmpfs

secrets ssh add <file>   # Add SSH key to Bitwarden
secrets gpg add <keyid>  # Add GPG key to Bitwarden
secrets files add <src> <dest>  # Add config file

# SOPS (encrypted rotatable secrets)
secrets sops edit        # Edit secrets.yaml
secrets sops show        # Show decrypted secrets
```

## Setup New Machine

### 1. Install NixOS

Boot the ISO, partition, and install minimal NixOS.

### 2. Bootstrap Bitwarden

If using Flatpak Bitwarden:
```sh
flatpak install com.bitwarden.desktop
```

The `secrets` CLI auto-detects Flatpak or native `bw`.

### 3. Pull Secrets

```sh
secrets login            # Prompts for email + master password (via pinentry)
secrets pull             # Pulls SSH keys, GPG keys, and config files
```

This:
- Loads SSH keys into ssh-agent
- Imports GPG keys into gpg keyring
- Stores config files in GNOME Keyring
- Exports age key for sops-nix

### 4. Build System

```sh
task switch HOST=<hostname>
```

After rebuild, secrets are auto-exported from keyring on login via `secrets-unlock.service`.

## Structure

```
hosts/              # Machine configs (per-host)
modules/            # NixOS modules (shared)
home/               # Home-manager configs (per-user)
pkgs/               # Custom packages
  secrets-cli/      #   Secrets management CLI
ops/                # Operational tooling
  tests/            #   Nix tests
```

## Adding a Host

1. Create `hosts/<name>/default.nix`
2. Add user config `home/<user>/<name>/default.nix`
3. Build: `task switch HOST=<name>`

## Adding Secrets

### SSH Key
```sh
secrets ssh add ~/.ssh/id_ed25519
```

### GPG Key
```sh
secrets gpg add <keyid>
```

### Config File
```sh
# Files stored in Bitwarden, exported to tmpfs at login
secrets files add ~/.kube/config '$XDG_RUNTIME_DIR/kube/config'
secrets files add ~/.ssh/hosts.conf '$XDG_RUNTIME_DIR/ssh/hosts.conf'

# Age key (special case - stored in keyring for sops-nix)
secrets files add ~/.config/sops/age/keys.txt keyring
```

### Rotatable Secret (sops)
```sh
secrets sops edit        # Add to secrets.yaml
# Then add to home/javad/secrets.nix:
# sops.secrets.my_secret.path = "${runtime}/path/to/secret";
```

## Acknowledgements

I actually don't have time to waste on nix lang or its syntax, so that is all @claude (opus), love that guy.

## TODOs

- auto-optimise-store
- bar tooling
- battery life optimization
- disk drive health
- cleanup tasks
- screen filtering
- QoL
- programs
- dev envs
