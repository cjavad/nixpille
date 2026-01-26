source (status dirname)/secrets-session.fish

function secrets_pull --argument-names BW BW_ITEM
    set -x BW_SESSION (bw_unlock $BW)
    test -n "$BW_SESSION" || return 1

    eval $BW sync
    set -l item_id (eval $BW list items --search "$BW_ITEM" | jq -r '.[0].id // empty')
    test -n "$item_id" || begin; echo "Item '$BW_ITEM' not found"; return 1; end

    mkdir -p (dirname $SECRETS_FILE)
    eval $BW get attachment secrets.yaml --itemid "$item_id" --output $SECRETS_FILE
    echo "Downloaded secrets.yaml"

    set -l tmp (_tmpfile)
    eval $BW get attachment keys.txt --itemid "$item_id" --output $tmp
    cat $tmp | age_key_set
    _shred $tmp

    echo "Age key stored in keyring"
end
