# GNOME Keyring / secret-tool operations
#
# Uses libsecret's secret-tool for keyring access

function keyring_get -a service key
    # Get value from keyring
    # Returns empty string if not found
    secret-tool lookup service $service type $key 2>/dev/null
end

function keyring_store -a service key label
    # Store value in keyring (reads from stdin)
    # label: human-readable description shown in Seahorse
    secret-tool store --label "$label" service $service type $key
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

function keyring_list_prefix -a service prefix
    # List all keys for a service that start with prefix
    secret-tool search --all service $service 2>/dev/null \
        | grep "^attribute.type" \
        | cut -d= -f2 \
        | tr -d ' ' \
        | while read -l key
            string match -q "$prefix*" "$key" && echo $key
        end
end

function keyring_has -a service key
    # Check if key exists
    test -n (keyring_get $service $key)
end

# === Convenience wrappers for our services ===

function keyring_get_file -a filename
    keyring_get $SECRETS_KEYRING_SERVICE $filename
end

function keyring_store_file -a filename
    # Reads content from stdin
    keyring_store $SECRETS_KEYRING_SERVICE $filename "nixpille: $filename"
end

function keyring_delete_file -a filename
    keyring_delete $SECRETS_KEYRING_SERVICE $filename
end

function keyring_get_bw_session
    keyring_get $SECRETS_KEYRING_BW_SERVICE session
end

function keyring_store_bw_session
    # Reads session from stdin
    keyring_store $SECRETS_KEYRING_BW_SERVICE session "Bitwarden Session"
end

function keyring_delete_bw_session
    keyring_delete $SECRETS_KEYRING_BW_SERVICE session
end

