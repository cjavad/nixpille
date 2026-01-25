# Home-manager entry point for javad
{
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ../common/lib.nix
    ./modules/shell.nix
    ./modules/hyprland.nix
    ./modules/vicinae.nix
    ./modules/flatpak.nix
    ./modules/languages.nix
    ./modules/php.nix
    ./modules/editors.nix
    ./modules/jetbrains.nix
    ./modules/cli.nix
    ./modules/devops.nix
    ./modules/backup.nix
    ./secrets.nix
    ./modules/nixos-config.nix
    ./modules/zen.nix
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
    home-manager
    gnupg
  ];

}
