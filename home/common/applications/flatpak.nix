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
    "com.jetbrains.PhpStorm"
    "com.jetbrains.PyCharm-Professional"
  ];

  # JetBrains Wayland support
  services.flatpak.overrides = {
    "com.jetbrains.PhpStorm" = {
      Context.sockets = [ "wayland" "fallback-x11" ];
      Environment._JAVA_OPTIONS = "-Dawt.toolkit.name=WLToolkit";
    };
    "com.jetbrains.PyCharm-Professional" = {
      Context.sockets = [ "wayland" "fallback-x11" ];
      Environment._JAVA_OPTIONS = "-Dawt.toolkit.name=WLToolkit";
    };
  };
}
