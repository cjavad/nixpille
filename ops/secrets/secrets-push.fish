source (status dirname)/secrets-session.fish

function secrets_push --argument-names BW BW_ITEM
    test -f $SECRETS_FILE || begin; echo "No secrets.yaml"; return 1; end
    grep -q "^sops:" $SECRETS_FILE || begin; echo "secrets.yaml not encrypted"; return 1; end
    age_key_export || begin; echo "No age key at $SOPS_AGE_KEY_FILE"; return 1; end

    set -x BW_SESSION (bw_unlock $BW)
    test -n "$BW_SESSION" || return 1

    eval $BW sync
    set -l item_id (eval $BW list items --search "$BW_ITEM" | jq -r '.[0].id // empty')

    if test -z "$item_id"
        set item_id (eval $BW get template item | jq ".name=\"$BW_ITEM\" | .type=2 | .secureNote.type=0" | eval $BW encode | eval $BW create item | jq -r '.id')
        echo "Created: $item_id"
    end

    for att in (eval $BW get item "$item_id" | jq -r '.attachments[]?.id // empty')
        eval $BW delete attachment $att --itemid "$item_id" 2>/dev/null
    end

    eval $BW create attachment --file $SECRETS_FILE --itemid "$item_id"
    eval $BW create attachment --file $SOPS_AGE_KEY_FILE --itemid "$item_id"
    eval $BW sync

    echo "Pushed to Bitwarden"
end
