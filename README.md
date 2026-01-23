# nixpille

Don't touch my files! I hate when programs modify files i don't control, data is data and code is code. Config is a weird middle ground that should be managed or disappear.

## Quick Start

```sh
# New machine - bootstrap secrets from Bitwarden
task secrets:login    # Login/unlock bw CLI
task secrets:pull     # Restore secrets.yaml + age key

# Build and switch
task switch HOST=<hostname>
```

## Commands

```sh
task switch          # Rebuild NixOS
task vm              # Test in VM
task check           # Validate flake
task fmt             # Format nix files
task secrets:edit    # Edit secrets
task secrets:pull    # Restore from Bitwarden
task secrets:push    # Backup to Bitwarden (manual)
```

Alias: `nixos-task` runs tasks from `~/.config/nixos-config`

## Structure

```
hosts/           # Machine configs (vm, ideapad, p1gen8)
modules/         # NixOS modules (core, desktop, secrets, services)
home/            # Home-manager config
  modules/       # User modules (shell, cli, editors, etc.)
dotfiles/        # Actual config files (fish, hypr, kitty, etc.)
```

## Secrets

Secrets are encrypted with sops/age. The age key and encrypted secrets are backed up to Bitwarden.

| File | Purpose |
|------|---------|
| `~/.config/sops/secrets.yaml` | Encrypted secrets |
| `~/.config/sops/age/keys.txt` | Private age key |
| `/run/secrets/*` | Decrypted at runtime |

### Bootstrap (new machine)

```sh
# Use bw CLI directly, or set BW for flatpak:
export BW="flatpak run --command=bw com.bitwarden.desktop"

task secrets:login    # Login + unlock, saves session
task secrets:pull     # Downloads secrets.yaml + age key
```

### Adding secrets

```sh
task secrets:add KEY=kubeconfig FILE=~/.kube/config  # Add file contents
task secrets:add KEY=api_token VALUE=abc123          # Add string value
task secrets:edit                                     # Or edit manually
```

### Backup to Bitwarden

Push is manual and requires secrets to exist locally first (pull before push):

```sh
task secrets:login    # If session expired
task secrets:push     # Uploads as Bitwarden attachments
```

## Adding a Host

1. Create `hosts/<name>/default.nix` with hardware config
2. Add to `flake.nix`: `<name> = mkHost ./hosts/<name>;`
3. Build: `task switch HOST=<name>`

## Acknowledgements

I actually don't have time to waste on nix lang or its syntax, so that is all @claude (opus), love that guy.
