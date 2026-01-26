# Runtime directory management (tmpfs)

function runtime_dir
    echo "/run/user/"(id -u)
end

function runtime_ensure -a subdir
    set -l dir (runtime_dir)/$subdir
    mkdir -p $dir
    chmod 700 $dir
    echo $dir
end

function runtime_shred -a subdir
    set -l dir (runtime_dir)/$subdir
    if test -d $dir
        find $dir -type f -exec shred -u {} \; 2>/dev/null
        rm -rf $dir
    end
end

function tmpfile
    mktemp -p (runtime_dir) "secrets-XXXXXX"
end

function shred_file -a path
    test -f $path && shred -u $path 2>/dev/null || rm -f $path
end
