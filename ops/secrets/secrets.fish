source (status dirname)/secrets-session.fish

function _sops_env
    age_key_export || begin; echo "No age key at $SOPS_AGE_KEY_FILE"; return 1; end
end

function _sops_get --argument-names key
    _sops_env && sops -d --extract "[\"$key\"]" $SECRETS_FILE 2>/dev/null
end

function _sops_set --argument-names key value
    _sops_env || return 1
    sops set $SECRETS_FILE "[\"$key\"]" (printf '%s' "$value" | jq -Rs .)
end

function _sops_del --argument-names key
    _sops_env && sops unset $SECRETS_FILE "[\"$key\"]" 2>/dev/null
end

function _sops_keys
    _sops_env && sops -d $SECRETS_FILE 2>/dev/null | grep -E '^[a-zA-Z_][a-zA-Z0-9_-]*:' | cut -d: -f1
end

# --- Auto-detect add ---

function secret_add_auto --argument-names file keyid name
    if test -n "$keyid"
        # GPG key by ID
        set -l tmp (_tmpfile)
        gpg --export-secret-keys --armor $keyid > $tmp 2>/dev/null
        test -s $tmp || begin; _shred $tmp; echo "GPG key not found: $keyid"; return 1; end

        test -z "$name" && set name (gpg --list-secret-keys $keyid 2>/dev/null | grep uid | head -1 | sed 's/.*<\(.*\)>.*/\1/' | tr '@.' '_')
        test -z "$name" && set name $keyid

        _sops_set "gpg_$name" (cat $tmp | string collect)
        _shred $tmp
        echo "Added: gpg_$name"

    else if test -n "$file"
        set file (eval echo $file)
        test -f $file || begin; echo "Not found: $file"; return 1; end

        set -l base (basename $file)
        set -l dir (dirname $file)

        # Auto-detect type from path
        if string match -q '*/.ssh/*' $file; or string match -q 'id_*' $base
            set -l key "ssh_$base"
            _sops_set $key (cat $file | string collect)
            echo "Added: $key"

        else if string match -q '*.conf' $base; and string match -q '*wireguard*' $dir
            set -l key "wg_"(basename $base .conf)
            _sops_set $key (cat $file | string collect)
            echo "Added: $key"

        else if test "$base" = "config"; and string match -q '*kube*' $dir
            _sops_set kubeconfig (cat $file | string collect)
            echo "Added: kubeconfig"

        else
            # Generic - use filename as key
            test -n "$name" && set key $name || set key (string replace -a '.' '_' $base)
            _sops_set $key (cat $file | string collect)
            echo "Added: $key"
        end
    else
        echo "Usage:"
        echo "  task secrets:add FILE=~/.ssh/id_ed25519"
        echo "  task secrets:add KEYID=ABC123"
        echo "  task secrets:add FILE=~/any/file NAME=custom_key"
        return 1
    end
end

function secret_remove --argument-names key
    test -z "$key" && begin; echo "Usage: task secrets:rm KEY=ssh_id_ed25519"; return 1; end
    _sops_del $key && echo "Removed: $key"
end

function secret_list
    echo "=== Secrets ==="
    for key in (_sops_keys)
        echo "  $key"
    end
end

# --- Sync all ---

function secrets_sync
    echo "Syncing local secrets..."

    # SSH
    for f in $HOME/.ssh/id_ed25519 $HOME/.ssh/id_rsa $HOME/.ssh/id_ecdsa
        test -f $f && secret_add_auto $f
    end

    # GPG
    for keyid in (gpg --list-secret-keys --keyid-format long 2>/dev/null | grep 'sec ' | sed 's/.*\/\([A-F0-9]*\).*/\1/')
        test -n "$keyid" && secret_add_auto "" $keyid
    end

    # Wireguard
    for f in $HOME/.config/wireguard/*.conf
        test -f $f && secret_add_auto $f
    end

    # Kubeconfig
    test -f $HOME/.kube/config && secret_add_auto $HOME/.kube/config

    manifest_generate
    echo ""
    echo "Done. Run: task secrets:push"
end

# --- Manifest ---

function manifest_generate
    set -l manifest (status dirname)/manifest.nix

    # Helper to format list for nix
    function _nix_list
        if test (count $argv) -eq 0
            echo ""
        else
            printf '"%s" ' $argv | string trim
        end
    end

    set -l ssh (_sops_keys | grep '^ssh_' | sed 's/^ssh_//' | string match -rv '^$')
    set -l gpg (_sops_keys | grep '^gpg_' | sed 's/^gpg_//' | string match -rv '^$')
    set -l wg (_sops_keys | grep '^wg_' | sed 's/^wg_//' | string match -rv '^$')

    printf '{\n  ssh = [%s];\n  gpg = [%s];\n  wg = [%s];\n}\n' \
        (_nix_list $ssh) \
        (_nix_list $gpg) \
        (_nix_list $wg) \
        > $manifest

    functions -e _nix_list
    echo "Generated: $manifest"
end
