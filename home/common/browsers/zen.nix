{ pkgs, inputs, ... }:

let
  addons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  # Tell Stylix which profile to theme
  stylix.targets.zen-browser.profileNames = [ "default" ];

  programs.zen-browser = {
    enable = true;
    nativeMessagingHosts = [ pkgs.firefoxpwa ];
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      OfferToSaveLogins = false;
      DontCheckDefaultBrowser = true;
    };
    profiles.default = {
      isDefault = true;
      extensions.packages = with addons; [
        ublock-origin
        bitwarden
        refined-github
      ];
      settings = {
        "browser.tabs.warnOnClose" = false;
        "zen.window-sync" = false;
        "zen.window-sync.open-link-in-new-unsynced-window" = true;
        "zen.window-sync.prefer-unsynced-windows" = true;
        "zen.window-sync.enabled" = false;
        # Screen sharing via PipeWire/WebRTC
        "media.webrtc.camera.allow-pipewire" = true;
        "media.webrtc.camera.allow-pipewire-screen-cast.enabled" = true;
      };
    };
  };
}
