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

function keyring_list -a service label_prefix
    # List all keys for a service by label prefix
    # Returns the key portion after the prefix (e.g., "SSH: foo" -> "ssh:foo")
    secret-tool search --all service $service 2>/dev/null \
        | grep "^label = $label_prefix" \
        | sed "s/^label = $label_prefix//" \
        | string trim
end

function keyring_list_prefix -a service prefix
    # List all keys for a service that start with prefix
    # Maps prefix to label: "ssh:" -> "SSH: ", "gpg:" -> "GPG: "
    switch $prefix
        case "ssh:"
            keyring_list $service "SSH: " | while read -l name
                echo "ssh:$name"
            end
        case "gpg:"
            keyring_list $service "GPG: " | while read -l name
                echo "gpg:$name"
            end
        case "*"
            # Fallback for other prefixes
            keyring_list $service "nixpille: " | while read -l name
                string match -q "$prefix*" "$name" && echo $name
            end
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

