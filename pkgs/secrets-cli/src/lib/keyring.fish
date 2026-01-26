# GNOME Keyring / secret-tool operations
#
# Uses libsecret's secret-tool for keyring access

function keyring_get -a service key
    # Get value from keyring
    # Returns empty string if not found
    secret-tool lookup service $service type $key 2>/dev/null
end

function keyring_store -a service key label value
    # Store value in keyring
    # label: human-readable description shown in Seahorse
    printf '%s' "$value" | secret-tool store --label "$label" service $service type $key
end

function keyring_delete -a service key
    # Delete from keyring (silent if not found)
    secret-tool clear service $service type $key 2>/dev/null
end

function keyring_list -a service
    # List all keys for a service
    secret-tool search --all service $service 2>/dev/null \
        | grep "^attribute.type" \
        | cut -d= -f2 \
        | tr -d ' '
end

function keyring_has -a service key
    # Check if key exists
    test -n (keyring_get $service $key)
end

# === Convenience wrappers for our services ===

function keyring_get_file -a filename
    keyring_get $SECRETS_KEYRING_SERVICE $filename
end

function keyring_store_file -a filename content
    keyring_store $SECRETS_KEYRING_SERVICE $filename "nixpille: $filename" "$content"
end

function keyring_delete_file -a filename
    keyring_delete $SECRETS_KEYRING_SERVICE $filename
end

function keyring_get_bw_session
    keyring_get $SECRETS_KEYRING_BW_SERVICE session
end

function keyring_store_bw_session -a session
    keyring_store $SECRETS_KEYRING_BW_SERVICE session "Bitwarden Session" $session
end

function keyring_delete_bw_session
    keyring_delete $SECRETS_KEYRING_BW_SERVICE session
end

function keyring_get_age_key
    keyring_get sops age-key
end

function keyring_store_age_key -a key
    keyring_store sops age-key "SOPS Age Key" "$key"
end
