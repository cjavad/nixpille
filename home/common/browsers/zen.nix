{ pkgs, inputs, ... }:

let
  addons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  # Tell Stylix which profile to theme
  stylix.targets.zen-browser.profileNames = [ "default" ];

  programs.zen-browser = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
    };
    profiles.default = {
      isDefault = true;
      extensions.packages = with addons; [
        ublock-origin
        bitwarden
        sponsorblock
        privacy-badger
      ];
      settings = {
        "browser.tabs.warnOnClose" = false;
      };
    };
  };
}
