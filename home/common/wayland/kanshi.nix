# Kanshi - dynamic monitor configuration
# Scripts in ops/monitors/, use `task monitors:*` commands
{ pkgs, ... }:

{
  home.packages = [
    pkgs.kanshi
    pkgs.wlr-randr
  ];

  # Kanshi service
  services.kanshi = {
    enable = true;
    systemdTarget = "graphical-session.target";

    # Default fallback - actual config managed via `task monitors:edit`
    settings = [
      {
        profile.name = "default";
        profile.outputs = [
          {
            criteria = "*";
            scale = 1.5;
          }
        ];
      }
    ];
  };
}
