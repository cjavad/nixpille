{ pkgs, ... }:

{
  services.mako = {
    enable = true;

    # Stylix handles colors, we set behavior and layout
    settings = {
      # General
      default-timeout = 5000;
      ignore-timeout = 0;
      max-visible = 5;
      layer = "overlay";
      anchor = "top-right";

      # Layout
      width = 380;
      height = 150;
      margin = "10";
      padding = "15";
      border-size = 2;
      border-radius = 12;

      # Icons
      icons = true;
      max-icon-size = 64;
      icon-path = "/run/current-system/sw/share/icons/Papirus-Dark";

      # Font (Stylix sets this but we can override)
      # font = "JetBrainsMono Nerd Font 11";

      # Actions
      actions = true;

      # Grouping
      group-by = "app-name";

      # Critical notifications stay until dismissed
      "urgency=critical" = {
        default-timeout = 0;
      };
    };
  };

  # Icon theme for notifications
  home.packages = with pkgs; [
    papirus-icon-theme
  ];
}
