# Main secrets entry point
#
# Three types of secrets:
#   SSH keys  → BW sshKey items → ssh-agent
#   GPG keys  → BW secure notes → gpg keyring
#   Files     → BW attachments  → keyring/tmpfs/disk

set -l script_dir (dirname (status filename))
source $script_dir/lib/bw.fish
source $script_dir/lib/keyring.fish
source $script_dir/lib/runtime.fish
source $script_dir/ssh.fish
source $script_dir/gpg.fish
source $script_dir/files.fish

function secrets_pull
    echo "Pulling from Bitwarden..."
    echo ""

    bw_session || return 1

    echo "=== Files ==="
    files_pull
    echo ""

    echo "=== SSH keys ==="
    ssh_pull
    echo ""

    echo "=== GPG keys ==="
    gpg_pull
    echo ""

    echo "Done."
end

function secrets_status
    echo "=== Status ==="
    echo ""

    echo "Keyring:"
    echo -n "  BW session: "
    test -n (keyring_get bitwarden session 2>/dev/null) && echo "yes" || echo "no"
    echo -n "  Age key:    "
    test -n (keyring_get sops age-key 2>/dev/null) && echo "yes" || echo "no"

    echo ""
    files_status

    echo ""
    ssh_status

    echo ""
    gpg_status
end

function secrets_lock
    echo "Clearing..."

    ssh-add -D 2>/dev/null
    echo "  SSH agent cleared"

    runtime_shred wireguard
    runtime_shred kube
    runtime_shred sops
    echo "  tmpfs cleared"

    bw_lock
    echo "Done."
end

function sops_edit
    # Export age key from keyring to tmpfs
    set -l key (keyring_get sops age-key 2>/dev/null)
    if test -z "$key"
        echo "No age key in keyring" >&2
        return 1
    end

    set -l sops_dir (runtime_ensure sops)
    printf '%s' "$key" > $sops_dir/keys.txt
    chmod 600 $sops_dir/keys.txt

    set -l secrets_file (dirname (status filename))/../../hosts/common/secrets/secrets.yaml
    SOPS_AGE_KEY_FILE=$sops_dir/keys.txt sops $secrets_file
end

function sops_show
    set -l key (keyring_get sops age-key 2>/dev/null)
    if test -z "$key"
        echo "No age key in keyring" >&2
        return 1
    end

    set -l sops_dir (runtime_ensure sops)
    printf '%s' "$key" > $sops_dir/keys.txt
    chmod 600 $sops_dir/keys.txt

    set -l secrets_file (dirname (status filename))/../../hosts/common/secrets/secrets.yaml
    SOPS_AGE_KEY_FILE=$sops_dir/keys.txt sops -d $secrets_file
end
