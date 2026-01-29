{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./shell.nix
    ./cli.nix
    ./github-token.nix
  ];

  home.stateVersion = "25.11";
  home.username = "javad";
  home.homeDirectory = "/home/javad";

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
    # Uses hostname to select config (e.g., homeConfigurations.vm)
    configFile."home-manager/flake.nix".text = ''
      {
        inputs.nixpille.url = "path:/etc/nixos";
        outputs = { nixpille, ... }: {
          homeConfigurations.javad = nixpille.homeConfigurations.''${builtins.getEnv "HOSTNAME"};
        };
      }
    '';
  };

  # Nautilus preferences
  dconf.settings = {
    "org/gnome/nautilus/icon-view" = {
      default-zoom-level = "small";
    };
    "org/gnome/nautilus/list-view" = {
      default-zoom-level = "small";
    };
    "org/gnome/desktop/interface" = {
      icon-theme = "Papirus-Dark";
    };
  };

  home.packages = with pkgs; [
    home-manager
    gnupg
    nautilus
  ];
}
