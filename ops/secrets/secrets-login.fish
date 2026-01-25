function secrets_login --argument-names BW
    set STATUS (eval $BW status | jq -r '.status // "error"')

    if test "$STATUS" = "unlocked"
        echo "Already unlocked"
        return 0
    end

    # Get password once
    set -x BW_PASSWORD (systemd-ask-password "Password:")

    if test "$STATUS" = "unauthenticated"
        read -P "Email: " EMAIL
        eval $BW login $EMAIL --raw --passwordenv BW_PASSWORD >/dev/null
        set STATUS (eval $BW status | jq -r '.status // "error"')
    end

    if test "$STATUS" = "locked"
        set SESSION (eval $BW unlock --raw --passwordenv BW_PASSWORD)
    end

    set -e BW_PASSWORD

    if test -z "$SESSION"
        echo "Failed to get session"
        return 1
    end

    echo $SESSION > ~/.bw-session
    echo "Session saved"
end
