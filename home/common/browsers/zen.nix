{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  addons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};

  vicinae-nmh-firefox = pkgs.writeTextDir "lib/mozilla/native-messaging-hosts/com.vicinae.vicinae.json" (
    builtins.toJSON {
      name = "com.vicinae.vicinae";
      description = "Vicinae Native Messaging Host";
      path = "${config.services.vicinae.package}/libexec/vicinae/vicinae-browser-link";
      type = "stdio";
      allowed_extensions = [ "vicinae@vicinae.com" ];
    }
  );

  zenXdgDir = "${config.xdg.configHome}/zen";
  zenLegacyDir = "${config.home.homeDirectory}/.zen";
in
{
  # Zen browser uses ~/.zen/ but the home-manager module manages ~/.config/zen/.
  # Keep a symlink so both resolve to the same location.
  home.activation.zenXdgSymlink = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    if [ ! -e "${zenLegacyDir}" ]; then
      mkdir -p "${zenXdgDir}"
      ln -s "${zenXdgDir}" "${zenLegacyDir}"
    fi
  '';

  # Tell Stylix which profile to theme
  stylix.targets.zen-browser.profileNames = [ "default" ];

  programs.zen-browser = {
    enable = true;
    nativeMessagingHosts = [
      pkgs.firefoxpwa
      vicinae-nmh-firefox
    ];
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
