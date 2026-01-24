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
      font_family = "JetBrainsMono Nerd Font";
      font_size = 14;
      theme = "catppuccin-mocha";
    };

    themes.catppuccin-mocha = {
      meta = {
        version = 1;
        name = "Catppuccin Mocha";
        description = "Soothing pastel theme for the high-spirited";
        variant = "dark";
        inherits = "vicinae-dark";
      };

      colors = {
        core = {
          background = "#1E1E2E";
          foreground = "#CDD6F4";
          secondary_background = "#181825";
          border = "#313244";
          accent = "#89B4FA";
        };
        accents = {
          blue = "#89B4FA";
          green = "#A6E3A1";
          magenta = "#F5C2E7";
          orange = "#FAB387";
          purple = "#CBA6F7";
          red = "#F38BA8";
          yellow = "#F9E2AF";
          cyan = "#94E2D5";
        };
      };
    };

    extensions = [ ];
  };
}
