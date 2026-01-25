{ pkgs, ... }:

let
  sddmTheme = pkgs.sddm-astronaut.override {
    themeConfig = {
      Background = "wallpapers/black.png";
      DimBackground = "0.0";
      CropBackground = "true";
      PartialBlur = "false";
      FullBlur = "false";
      HaveFormBackground = "false";
      FormPosition = "center";
      HideVirtualKeyboard = "true";
      HideLoginButton = "true";
      ForceLastUser = "true";
      PasswordFocus = "true";
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
      Font = "JetBrainsMono Nerd Font";
      FontSize = "12";
      HeaderText = "";
    };
  };
in
{
  services.displayManager = {
    defaultSession = "hyprland-uwsm";
    sddm = {
      enable = true;
      wayland.enable = true;
      theme = "sddm-astronaut-theme";
      extraPackages = [ sddmTheme ];
      settings.Theme.CursorTheme = "capitaine-cursors";
    };
  };

  environment.systemPackages = [
    sddmTheme
    pkgs.kdePackages.qtmultimedia
    pkgs.capitaine-cursors
  ];
}
