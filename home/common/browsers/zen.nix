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

  # Minimal seed. Zen rewrites this on first launch to add [Install<HASH>] and
  # [InstallsDiscovered] sections once the file is user-writable.
  zenProfilesIniSeed = pkgs.writeText "zen-profiles.ini" ''
    [Profile0]
    Name=default
    IsRelative=1
    Path=default
    Default=1

    [General]
    StartWithLastProfile=1
    Version=2
  '';
in
{
  # Tell Stylix which profile to theme
  stylix.targets.zen-browser.profileNames = [ "default" ];

  # Workaround for https://github.com/0xc000022070/zen-browser-flake/issues/285
  # home-manager's firefox module writes a minimal `Version=2` profiles.ini as a
  # read-only /nix/store symlink, which blocks Firefox's Selectable-Profiles
  # migration. Side-effects: corrupt sessionstore (tabs don't restore), the
  # workspace "Create space" button is disabled, history writes skipped. So:
  #   1. stop home-manager from managing profiles.ini
  #   2. seed it ourselves into a writable regular file on activation (idempotent)
  home.file."${zenXdgDir}/profiles.ini".enable = lib.mkForce false;

  home.activation.zenBootstrapProfilesIni = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    profilesIni="${zenXdgDir}/profiles.ini"
    if [ ! -e "$profilesIni" ] || [ -L "$profilesIni" ]; then
      [ -L "$profilesIni" ] && run rm "$profilesIni"
      run install -Dm 644 ${zenProfilesIniSeed} "$profilesIni"
    fi
  '';

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
        # Screen sharing via PipeWire/WebRTC
        "media.webrtc.camera.allow-pipewire" = true;
        "media.webrtc.camera.allow-pipewire-screen-cast.enabled" = true;
        # Window sync = cross-window tab replication. Disabling only this is
        # fine — it does NOT mark windows as "unsynced" internally, so
        # workspaces, session restore, and history persistence keep working.
        "zen.window-sync.enabled" = false;
        # Must stay false: `true` marks newly opened windows as unsynced,
        # which disables "Create space", skips sessionstore persistence, and
        # drops history writes for those windows.
        "zen.window-sync.prefer-unsynced-windows" = false;
      };
    };
  };
}
