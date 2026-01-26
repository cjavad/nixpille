{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    # Desktop
    ./modules/hyprland.nix
    ./modules/waybar.nix
    ./modules/kitty.nix
    ./modules/mako.nix
    ./modules/vicinae.nix

    # Shell & CLI
    ./modules/shell.nix
    ./modules/cli.nix

    # Development
    ./modules/languages.nix
    ./modules/php.nix
    ./modules/editors.nix
    ./modules/devops.nix

    # Communication
    ./modules/thunderbird.nix

    # System
    ./modules/keyring.nix
    ./modules/flatpak.nix
    ./modules/backup.nix
    ./modules/nixos-config.nix
    ./modules/zen.nix
    ./modules/github-token.nix
    ./secrets.nix
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
    mimeApps = {
      enable = true;
      defaultApplications = {
        # Zen browser for web
        "text/html" = "zen.desktop";
        "x-scheme-handler/http" = "zen.desktop";
        "x-scheme-handler/https" = "zen.desktop";
        "x-scheme-handler/about" = "zen.desktop";
        "x-scheme-handler/unknown" = "zen.desktop";
        "application/xhtml+xml" = "zen.desktop";

        # Nautilus for files/folders
        "inode/directory" = "org.gnome.Nautilus.desktop";
        "application/x-gnome-saved-search" = "org.gnome.Nautilus.desktop";
      };
    };
    # Proxy flake for `home-manager switch` without arguments
    configFile."home-manager/flake.nix".text = ''
      {
        inputs.nixpille.url = "path:${config.home.homeDirectory}/Dev/nixpille";
        outputs = { nixpille, ... }: { inherit (nixpille) homeConfigurations; };
      }
    '';
  };

  home.packages = with pkgs; [
    home-manager
    gnupg
    nautilus
  ];
}
