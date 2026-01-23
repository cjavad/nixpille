{ dotfiles, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Search & navigation
    fd
    ripgrep
    bat
    eza
    tree

    # Data processing
    jq
    yq

    # System monitoring
    htop
    btop
    fastfetch

    # Terminal multiplexers
    tmux
    zellij

    # Dev utilities
    dive
    cloc

    # Media CLI
    ffmpeg

    # Fish greeting (fortune | cowsay | lolcat)
    fortune
    cowsay
    lolcat
  ];

  # tmux config from dotfiles (mutable, editable directly)
  xdg.configFile."tmux".source = dotfiles.link "tmux";
}
