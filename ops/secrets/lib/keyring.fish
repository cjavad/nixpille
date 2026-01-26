# GNOME Keyring / secret-tool helpers

function keyring_get -a service key
    secret-tool lookup service $service type $key 2>/dev/null
end

function keyring_store -a service key label value
    printf '%s' "$value" | secret-tool store --label "$label" service $service type $key
end

function keyring_delete -a service key
    secret-tool clear service $service type $key 2>/dev/null
end

function keyring_list -a service
    secret-tool search --all service $service 2>/dev/null | grep "^attribute.type" | cut -d= -f2 | tr -d ' '
end
