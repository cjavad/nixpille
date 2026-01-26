# SSH key management: BW sshKey items (type 5) → ssh-agent

set -l script_dir (dirname (status filename))
source $script_dir/lib/bw.fish
source $script_dir/lib/runtime.fish

function ssh_pull
    bw_session || return 1

    set -l keys (bw_list_ssh)
    if test -z "$keys"
        echo "No SSH keys in BW"
        return 0
    end

    set -l runtime (runtime_ensure ssh)
    set -l loaded 0

    for name in $keys
        set -l privkey (bw_get_ssh $name 2>/dev/null)
        test -z "$privkey" && continue

        # Write to tmpfs temporarily
        printf '%s\n' $privkey > $runtime/$name
        chmod 600 $runtime/$name

        # Add to agent
        SSH_ASKPASS_REQUIRE=never ssh-add $runtime/$name 2>/dev/null
        and set loaded (math $loaded + 1)
        and echo "  $name"

        # Remove from tmpfs
        rm -f $runtime/$name
    end

    rmdir $runtime 2>/dev/null
    echo "Loaded $loaded keys"
end

function ssh_add -a keyfile
    if test -z "$keyfile"
        echo "Usage: ssh_add <path_to_key>"
        return 1
    end

    set keyfile (eval echo $keyfile)
    test -f $keyfile || begin; echo "File not found: $keyfile"; return 1; end

    bw_session || return 1

    set -l name (basename $keyfile)
    set -l privkey (cat $keyfile)
    set -l pubkey
    set -l fingerprint

    # Get public key
    if test -f "$keyfile.pub"
        set pubkey (cat "$keyfile.pub")
    else
        set pubkey (ssh-keygen -y -f $keyfile 2>/dev/null)
    end

    # Get fingerprint
    set fingerprint (ssh-keygen -lf $keyfile 2>/dev/null | awk '{print $2}')

    bw_create_ssh $name "$privkey" "$pubkey" "$fingerprint"
    echo "Added: $name"
end

function ssh_rm -a name
    if test -z "$name"
        echo "Usage: ssh_rm <key_name>"
        return 1
    end

    bw_session || return 1

    set -l item ($BW_CLI get item $name 2>/dev/null)
    if test -z "$item"
        echo "Not found: $name"
        return 1
    end

    set -l item_id (echo $item | jq -r '.id')
    $BW_CLI delete item $item_id
    $BW_CLI sync
    echo "Removed: $name"
end

function ssh_list
    bw_session || return 1
    echo "SSH keys:"
    bw_list_ssh | while read name
        echo "  $name"
    end
end

function ssh_status
    echo "SSH Agent:"
    ssh-add -l 2>/dev/null || echo "  (empty)"
end
