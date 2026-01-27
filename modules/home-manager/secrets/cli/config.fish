# Configuration for secrets-cli
#
# All settings can be overridden via environment variables.
# User config file: ~/.config/secrets/config.fish (optional)

# Load user config if exists
set -l user_config "$HOME/.config/secrets/config.fish"
test -f $user_config && source $user_config

# === Bitwarden CLI ===
# Detect BW command: prefer env var, then flatpak, then native
if not set -q SECRETS_BW_CLI
    if command -q flatpak; and flatpak list 2>/dev/null | grep -q com.bitwarden.desktop
        set -g SECRETS_BW_CLI flatpak run --command=bw com.bitwarden.desktop
    else if command -q bw
        set -g SECRETS_BW_CLI bw
    else
        set -g SECRETS_BW_CLI ""
    end
end

# Split BW command for execution (handles "flatpak run --command=bw ...")
set -g BW_CMD (string split ' ' -- $SECRETS_BW_CLI)

# === Item naming ===
# Prefix for file storage item in BW
set -q SECRETS_FILES_ITEM_PREFIX || set -g SECRETS_FILES_ITEM_PREFIX "nixpille-files"
# Prefix for GPG keys (secure notes)
set -q SECRETS_GPG_PREFIX || set -g SECRETS_GPG_PREFIX "gpg-"

# === Keyring ===
# Service name for GNOME Keyring storage
set -q SECRETS_KEYRING_SERVICE || set -g SECRETS_KEYRING_SERVICE "nixpille"
# Service for BW session
set -q SECRETS_KEYRING_BW_SERVICE || set -g SECRETS_KEYRING_BW_SERVICE "bitwarden"

# === Pinentry ===
set -q SECRETS_PINENTRY || set -g SECRETS_PINENTRY "pinentry-qt"
# Password cache timeout in seconds (0 = no cache)
set -q SECRETS_PASSWORD_CACHE_TTL || set -g SECRETS_PASSWORD_CACHE_TTL 60

# === Logging ===
# Log level: debug, info, warn, error
set -q SECRETS_LOG_LEVEL || set -g SECRETS_LOG_LEVEL "info"

# === Runtime ===
# XDG_RUNTIME_DIR with fallback
set -q XDG_RUNTIME_DIR || set -g XDG_RUNTIME_DIR "/run/user/"(id -u)
set -g SECRETS_RUNTIME_DIR $XDG_RUNTIME_DIR

# === Paths ===
# Where sops keys are stored
set -g SECRETS_SOPS_DIR "$SECRETS_RUNTIME_DIR/sops"
# Where SSH keys are temporarily written
set -g SECRETS_SSH_DIR "$SECRETS_RUNTIME_DIR/ssh"

# === Derived ===
# Full files item name
set -g SECRETS_FILES_ITEM "$SECRETS_FILES_ITEM_PREFIX-$USER"

# Print configuration (for debugging)
function config_show
    echo "Configuration:"
    echo "  BW CLI:        $SECRETS_BW_CLI"
    echo "  Files item:    $SECRETS_FILES_ITEM"
    echo "  GPG prefix:    $SECRETS_GPG_PREFIX"
    echo "  Keyring:       $SECRETS_KEYRING_SERVICE"
    echo "  Pinentry:      $SECRETS_PINENTRY"
    echo "  Log level:     $SECRETS_LOG_LEVEL"
    echo "  Runtime dir:   $SECRETS_RUNTIME_DIR"
    echo ""
    echo "Environment overrides:"
    echo "  SECRETS_BW_CLI, SECRETS_FILES_ITEM_PREFIX, SECRETS_GPG_PREFIX"
    echo "  SECRETS_KEYRING_SERVICE, SECRETS_PINENTRY, SECRETS_LOG_LEVEL"
    echo "  SECRETS_NO_COLOR"
    echo ""
    echo "User config: $user_config"
    test -f $user_config && echo "  (loaded)" || echo "  (not found)"
end

# Validate configuration
function config_validate
    if test -z "$SECRETS_BW_CLI"
        log_error "Bitwarden CLI not found"
        log_error "Install with: nix-shell -p bitwarden-cli"
        log_error "Or use flatpak: flatpak install com.bitwarden.desktop"
        return 1
    end
    return 0
end
