function secrets_add --argument-names KEY FILE VALUE
    set SECRETS ~/.config/sops/secrets.yaml

    if test -z "$KEY"
        echo "Usage: task secrets:add KEY=<name> FILE=<path> or VALUE=<string>"
        return 1
    end

    if test -z "$FILE" -a -z "$VALUE"
        echo "Provide FILE or VALUE"
        return 1
    end

    if test -n "$FILE"
        set FILE (eval echo "$FILE")
        if not test -f "$FILE"
            echo "File not found: $FILE"
            return 1
        end
        set VAL (jq -Rs . < "$FILE")
        sops set "$SECRETS" "[\"$KEY\"]" "$VAL"
        echo "Added $KEY from $FILE"
    else
        set VAL (echo -n "$VALUE" | jq -Rs .)
        sops set "$SECRETS" "[\"$KEY\"]" "$VAL"
        echo "Added $KEY"
    end
end
