# Runtime directory (tmpfs) management
#
# All secrets on tmpfs are ephemeral - cleared on reboot

function runtime_dir
    # Get runtime directory
    echo $SECRETS_RUNTIME_DIR
end

function runtime_ensure -a subdir
    # Ensure subdirectory exists with proper permissions
    set -l dir $SECRETS_RUNTIME_DIR/$subdir
    mkdir -p $dir
    chmod 700 $dir
    echo $dir
end

function runtime_shred -a subdir
    # Securely delete a subdirectory
    set -l dir $SECRETS_RUNTIME_DIR/$subdir
    if test -d $dir
        # Shred all files
        find $dir -type f -exec shred -u {} \; 2>/dev/null
        rm -rf $dir
        log_debug "Shredded: $dir"
    end
end

function runtime_tmpfile -a prefix
    # Create temporary file in runtime dir
    set -q prefix[1] || set prefix "secrets"
    mktemp -p $SECRETS_RUNTIME_DIR "$prefix-XXXXXX"
end

function runtime_shred_file -a path
    # Securely delete a single file
    if test -f $path
        shred -u $path 2>/dev/null
        or rm -f $path
    end
end

function runtime_write -a path content
    # Write content to file with secure permissions
    set -l dir (dirname $path)
    mkdir -p $dir 2>/dev/null
    chmod 700 $dir 2>/dev/null

    umask 077
    printf '%s' "$content" > $path
    chmod 600 $path
end

function runtime_exists -a subdir
    # Check if subdirectory exists and has files
    set -l dir $SECRETS_RUNTIME_DIR/$subdir
    test -d $dir && test -n (ls -A $dir 2>/dev/null)
end
