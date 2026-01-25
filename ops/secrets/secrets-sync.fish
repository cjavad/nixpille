for f in ~/.ssh/id_* ~/.ssh/config
    test -f "$f"; or continue
    task secrets:add KEY=ssh_(basename "$f") FILE="$f"
end

for f in ~/.config/wireguard/*.conf
    test -f "$f"; or continue
    task secrets:add KEY=wg_(basename "$f" .conf) FILE="$f"
end

test -f ~/.config/k9s/config.yaml
and task secrets:add KEY=k9s_config FILE=~/.config/k9s/config.yaml

task secrets:manifest
echo "Run 'task secrets:push' to backup."
