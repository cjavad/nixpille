{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  services.flatpak.packages = [
    "dev.vencord.Vesktop"
    "com.slack.Slack"
  ];
}
