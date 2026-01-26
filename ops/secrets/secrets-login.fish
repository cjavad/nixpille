source (status dirname)/secrets-session.fish

function secrets_login --argument-names BW
    set -l bw_status (eval $BW status | jq -r '.status')

    switch $bw_status
        case unlocked
            echo "Already unlocked"

        case unauthenticated
            read -P "Email: " email
            set -l pass (_pinentry "Bitwarden Master Password")
            test -z "$pass" && return 1

            # Login interactively (2FA prompt will show)
            set -x BW_PASSWORD "$pass"
            eval $BW login $email --passwordenv BW_PASSWORD; set -l login_status $status
            set -e BW_PASSWORD
            test $login_status -ne 0 && return 1

            # After login, vault is locked - unlock it with same password
            set -l session (bw_unlock $BW $pass)
            test -z "$session" && return 1
            echo "Logged in and unlocked"

        case locked
            set -l session (bw_unlock $BW)
            test -n "$session" && echo "Unlocked" || return 1

        case '*'
            echo "Status: $bw_status"
            return 1
    end
end
