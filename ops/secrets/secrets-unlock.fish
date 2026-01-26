source (status dirname)/secrets-session.fish
source (status dirname)/secrets.fish

function secrets_unlock
    echo "Exporting to tmpfs..."

    age_key_export || begin; echo "No age key in keyring"; return 1; end
    echo "  age → $SOPS_DIR/keys.txt"

    # SSH → agent
    for key in (_sops_keys | grep '^ssh_')
        set -l tmp (_tmpfile)
        _sops_get $key > $tmp
        chmod 600 $tmp
        SSH_ASKPASS_REQUIRE=never ssh-add $tmp 2>/dev/null; or ssh-add $tmp 2>/dev/null
        _shred $tmp
        echo "  $key → agent"
    end

    # GPG → gpg keyring
    for key in (_sops_keys | grep '^gpg_')
        _sops_get $key | gpg --batch --import 2>/dev/null
        echo "  $key → gpg"
    end

    # Wireguard → tmpfs
    mkdir -p "$RUNTIME_DIR/wireguard" && chmod 700 "$RUNTIME_DIR/wireguard"
    for key in (_sops_keys | grep '^wg_')
        set -l name (string replace 'wg_' '' $key)
        _sops_get $key > "$RUNTIME_DIR/wireguard/$name.conf"
        chmod 600 "$RUNTIME_DIR/wireguard/$name.conf"
        echo "  $key → wireguard/$name.conf"
    end

    # Kubeconfig → tmpfs
    if contains kubeconfig (_sops_keys)
        mkdir -p "$RUNTIME_DIR/kube" && chmod 700 "$RUNTIME_DIR/kube"
        _sops_get kubeconfig > "$RUNTIME_DIR/kube/config"
        chmod 600 "$RUNTIME_DIR/kube/config"
        echo "  kubeconfig → kube/config"
    end

    echo "Done"
end

function secrets_lock
    echo "Clearing tmpfs..."
    for dir in $SOPS_DIR "$RUNTIME_DIR/wireguard" "$RUNTIME_DIR/kube"
        test -d $dir && find $dir -type f -exec shred -u {} \; 2>/dev/null && rm -rf $dir
    end
    echo "Done"
end

function secrets_status
    echo "Keyring: "(test -n (age_key_get) && echo "✓" || echo "✗")
    echo "tmpfs:   "(test -f "$SOPS_DIR/keys.txt" && echo "✓" || echo "✗")
    echo "Agent:   "(ssh-add -l 2>/dev/null | wc -l)" keys"
    echo ""
    secret_list
end
