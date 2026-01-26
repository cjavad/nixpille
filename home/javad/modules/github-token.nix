{ pkgs, ... }:

{
  home.packages = [ pkgs.gh ];

  systemd.user.services.nix-github-token = {
    Unit.Description = "Update Nix GitHub token from gh CLI";
    Service = {
      Type = "oneshot";
      ExecStart = toString (
        pkgs.writeShellScript "update-gh-token" ''
          TOKEN=$(${pkgs.gh}/bin/gh auth token 2>/dev/null) || exit 0
          if [ -n "$TOKEN" ]; then
            echo "access-tokens = github.com=$TOKEN" | sudo tee /etc/nix/github-token.conf > /dev/null
            sudo chmod 600 /etc/nix/github-token.conf
          fi
        ''
      );
    };
  };

  systemd.user.timers.nix-github-token = {
    Unit.Description = "Refresh Nix GitHub token periodically";
    Install.WantedBy = [ "timers.target" ];
    Timer = {
      OnBootSec = "1min";
      OnUnitActiveSec = "6h";
    };
  };
}
