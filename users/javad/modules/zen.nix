# Zen Browser with declarative extensions
{ pkgs, inputs, ... }:

let
  addons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};
in
{
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
        darkreader
        sponsorblock
        privacy-badger
      ];
    };
  };
}
