{ pkgs, ... }:

let
  # Custom astronaut theme with our config
  sddmTheme = pkgs.sddm-astronaut.override {
    themeConfig = {
      # Background
      Background = "wallpapers/black.png";
      DimBackground = "0.0";
      CropBackground = "true";

      # Clean look - no blur
      PartialBlur = "false";
      FullBlur = "false";

      # Form
      HaveFormBackground = "false";
      FormPosition = "center";

      # Hide clutter
      HideVirtualKeyboard = "true";
      HideLoginButton = "true";

      # Behavior
      ForceLastUser = "true";
      PasswordFocus = "true";

      # Catppuccin Mocha colors
      HeaderTextColor = "#cdd6f4";
      DateTextColor = "#6c7086";
      InputTextColor = "#cdd6f4";
      InputPlaceholderTextColor = "#6c7086";
      InputBackgroundColor = "#313244";
      InputBorderColor = "#45475a";
      InputBorderFocusColor = "#89b4fa";
      LoginButtonTextColor = "#1e1e2e";
      LoginButtonBackgroundColor = "#89b4fa";
      SystemButtonIconColor = "#cdd6f4";
      SystemButtonBackgroundColor = "#313244";

      # Font
      Font = "JetBrainsMono Nerd Font";
      FontSize = "12";

      # No header
      HeaderText = "";
    };
  };
in
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-astronaut-theme";
    extraPackages = [ sddmTheme ];
    settings.Theme.CursorTheme = "capitaine-cursors";
  };

  environment.systemPackages = [
    sddmTheme
    pkgs.kdePackages.qtmultimedia
    pkgs.capitaine-cursors # Cursor theme for SDDM
  ];
}
