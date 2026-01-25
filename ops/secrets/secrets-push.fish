function secrets_push --argument-names BW BW_ITEM
    set SECRETS ~/.config/sops/secrets.yaml
    set AGE_KEY ~/.config/sops/age/keys.txt

    test -f $SECRETS; or begin; echo "No secrets - run: task secrets:pull"; return 1; end
    test -f $AGE_KEY; or begin; echo "No age key - run: task secrets:pull"; return 1; end
    grep -q "^sops:" $SECRETS; or begin; echo "secrets.yaml not encrypted!"; return 1; end
    test -f ~/.bw-session; or begin; echo "Run: task secrets:login"; return 1; end

    set -x BW_SESSION (cat ~/.bw-session)
    test (eval $BW status | jq -r '.status') = "unlocked"; or begin; echo "Run: task secrets:login"; return 1; end

    eval $BW sync
    set ITEM_ID (eval $BW list items --search "$BW_ITEM" | jq -r '.[0].id // empty')

    if test -z "$ITEM_ID"
        set ITEM_ID (eval $BW get template item | jq ".name=\"$BW_ITEM\" | .type=2 | .secureNote.type=0" | eval $BW encode | eval $BW create item | jq -r '.id')
        echo "Created item: $ITEM_ID"
    end

    for att in (eval $BW get item "$ITEM_ID" | jq -r '.attachments[]?.id // empty')
        eval $BW delete attachment $att --itemid "$ITEM_ID" 2>/dev/null; or true
    end

    eval $BW create attachment --file $SECRETS --itemid "$ITEM_ID"
    eval $BW create attachment --file $AGE_KEY --itemid "$ITEM_ID"
    eval $BW sync
    echo "Pushed to Bitwarden"
end
