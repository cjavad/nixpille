if status is-interactive
    # Commands to run in interactive sessions can go here
end

function fish_greeting
    fortune | cowsay -f (cowsay -l | tail -n +2 | tr ' ' '\n' | grep . | shuf -n1) | lolcat -S (random)
end

# environment variables
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER less
set -gx LESS '-g -i -M -R -S -w -X -z-4'

# aliases
alias task go-task
alias ssh "TERM=xterm-256color command ssh"
alias claude "$HOME/.claude/local/claude"
alias nixos-task "task -d ~/.config/nixos-config"

# direnv
direnv hook fish | source

# Google Cloud SDK
if [ -f '/home/javad/.google-cloud-sdk/path.fish.inc' ]; . '/home/javad/.google-cloud-sdk/path.fish.inc'; end
