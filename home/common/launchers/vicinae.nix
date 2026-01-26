{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [ inputs.vicinae.homeManagerModules.default ];

  services.vicinae = {
    enable = true;

    systemd = {
      enable = true;
      autoStart = true;
    };

    settings = {
      close_on_focus_loss = true;
      # Font and theme handled by Stylix
      window_width = 800;
    };

    # Native vicinae extensions (from vicinae-extensions flake)
    extensions = with inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}; [
      # Raycast extensions like Bitwarden: install from within vicinae
      # Open vicinae -> type "store" -> search "bitwarden" -> install
    ];
  };

  systemd.user.services.vicinae = {
    Unit = {
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
