{
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./modules/lib.nix
    ./modules/shell.nix
    ./modules/hyprland.nix
    ./modules/vicinae.nix
    ./modules/flatpak.nix
    ./modules/languages.nix
    ./modules/php.nix
    ./modules/editors.nix
    ./modules/jetbrains.nix
    ./modules/cli.nix
    ./modules/kubernetes.nix
    ./modules/backup.nix
    ./modules/secrets.nix
    ./modules/nixos-config.nix
  ];

  home.stateVersion = "25.11";
  home.username = "javad";
  home.homeDirectory = "/home/javad";

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    settings = {
      user.name = "Javad";
      user.email = "me@javad.sh";
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  home.packages = with pkgs; [
    gh
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

}
