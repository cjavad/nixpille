# nixpille

Don't touch my files! I hate when programs modify files i don't control, data is data and code is code. Config is a weird middle ground that should be managed or disappear.

## Quick Start

```sh
# New machine
export BW="flatpak run --command=bw com.bitwarden.desktop"  # if using flatpak
task secrets:login && task secrets:pull
task switch HOST=<hostname>
```

## Commands

```sh
task switch          # Rebuild NixOS
task vm              # Test in VM
task check           # Validate flake
task fmt             # Format nix files
```

## Secrets

Secrets are encrypted with age and stored in `~/.config/sops/secrets.yaml`. The age key lives in GNOME Keyring and is exported to tmpfs at login. sops-nix decrypts secrets to `/run/user/<uid>/` so plaintext never touches disk. Bitwarden is used for backup/sync across machines.

```sh
task secrets:login   # Auth with Bitwarden
task secrets:pull    # Pull from Bitwarden
task secrets:push    # Push to Bitwarden
task secrets:sync    # Sync local files to sops
task secrets:add     # Add secret: FILE=path or KEYID=gpg
```

Naming: `ssh_*`, `gpg_*`, `wg_*` are auto-deployed on rebuild.

## Structure

```
hosts/              # Machine configs
modules/            # NixOS modules
home/               # Home-manager user configs
ops/                # Operational tooling
  scripts/          #   Shell scripts
  secrets/          #   sops secrets
  tasks/            #   Taskfile includes
  tests/            #   Nix tests
```

## Adding a Host

1. Create `hosts/<name>/default.nix`
2. Add to `flake.nix`: `<name> = mkHost ./hosts/<name>;`
3. Build: `task switch HOST=<name>`

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