{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  # Electron app override: native Wayland + client-side decorations (no title bar)
  electronApp = {
    Context.sockets = [ "wayland" "fallback-x11" ];
    Environment = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      GTK_CSD = "1";
    };
  };
in
{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  services.flatpak.packages = [
    "dev.vencord.Vesktop"
    "com.slack.Slack"
  ];

  services.flatpak.overrides = {
    # Global: XDG portal access for opening links
    global = {
      Context.sockets = [ "session-bus" ];
      Context.filesystems = [ "xdg-run/pipewire-0" ];
      "Session Bus Policy" = {
        "org.freedesktop.portal.Desktop" = "talk";
        "org.freedesktop.portal.FileChooser" = "talk";
        "org.freedesktop.portal.OpenURI" = "talk";
        "org.freedesktop.portal.Settings" = "talk";
      };
    };

    # Electron apps
    "com.slack.Slack" = electronApp;
  };
}
