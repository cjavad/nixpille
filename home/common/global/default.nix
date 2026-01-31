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
    signing = {
      key = "F1FECA8D7F2F2861";
      signByDefault = true;
    };
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
        "text/html" = "zen-beta.desktop";
        "x-scheme-handler/http" = "zen-beta.desktop";
        "x-scheme-handler/https" = "zen-beta.desktop";
        "x-scheme-handler/about" = "zen-beta.desktop";
        "x-scheme-handler/unknown" = "zen-beta.desktop";
        "application/xhtml+xml" = "zen-beta.desktop";

        # Nautilus for files/folders
        "inode/directory" = "org.gnome.Nautilus.desktop";
        "application/x-gnome-saved-search" = "org.gnome.Nautilus.desktop";

        # Loupe for images
        "image/png" = "org.gnome.Loupe.desktop";
        "image/jpeg" = "org.gnome.Loupe.desktop";
        "image/gif" = "org.gnome.Loupe.desktop";
        "image/webp" = "org.gnome.Loupe.desktop";
        "image/svg+xml" = "org.gnome.Loupe.desktop";
        "image/bmp" = "org.gnome.Loupe.desktop";
        "image/tiff" = "org.gnome.Loupe.desktop";
        "image/avif" = "org.gnome.Loupe.desktop";
        "image/heif" = "org.gnome.Loupe.desktop";

        # mpv for video & audio
        "video/mp4" = "mpv.desktop";
        "video/x-matroska" = "mpv.desktop";
        "video/webm" = "mpv.desktop";
        "video/x-msvideo" = "mpv.desktop";
        "video/quicktime" = "mpv.desktop";
        "video/ogg" = "mpv.desktop";
        "audio/mpeg" = "mpv.desktop";
        "audio/ogg" = "mpv.desktop";
        "audio/flac" = "mpv.desktop";
        "audio/x-wav" = "mpv.desktop";

        # Papers for documents
        "application/pdf" = "org.gnome.Papers.desktop";
        "application/epub+zip" = "org.gnome.Papers.desktop";
        "image/vnd.djvu" = "org.gnome.Papers.desktop";
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
  ];
}
