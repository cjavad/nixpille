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

Encrypted with sops/age, backed up to Bitwarden.

```sh
task secrets:login   # Auth with Bitwarden
task secrets:pull    # Restore from Bitwarden
task secrets:push    # Backup to Bitwarden
task secrets:sync    # Sync local files → sops (ssh, wg, gpg, k9s)
task secrets:add     # Add single secret: KEY=name FILE=path or VALUE=string
task secrets:edit    # Pull → edit → push
```

Naming: `ssh_<file>`, `wg_<name>`, `gpg_<name>` → auto-deployed on rebuild.

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