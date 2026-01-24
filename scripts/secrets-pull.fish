function secrets_pull --argument-names BW BW_ITEM
    set SECRETS ~/.config/sops/secrets.yaml
    set AGE_KEY ~/.config/sops/age/keys.txt

    test -f ~/.bw-session; or begin; echo "Run: task secrets:login"; return 1; end

    set -x BW_SESSION (cat ~/.bw-session)
    test (eval $BW status | jq -r '.status') = "unlocked"; or begin; echo "Run: task secrets:login"; return 1; end

    eval $BW sync
    set ITEM_ID (eval $BW list items --search "$BW_ITEM" | jq -r '.[0].id // empty')
    test -n "$ITEM_ID"; or begin; echo "Item '$BW_ITEM' not found"; return 1; end

    mkdir -p (dirname $AGE_KEY)
    eval $BW get attachment secrets.yaml --itemid "$ITEM_ID" --output $SECRETS
    eval $BW get attachment keys.txt --itemid "$ITEM_ID" --output $AGE_KEY
    chmod 600 $AGE_KEY
    echo "Secrets restored"
end
