{ dotfiles, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Core utilities
    git
    vim
    curl
    unzip

    # Search & navigation
    fd
    ripgrep
    bat
    eza
    tree

    # Data processing
    jq
    yq-go

    # System monitoring
    htop
    btop
    fastfetch

    # Terminal multiplexers
    tmux
    zellij

    # Dev utilities
    go-task
    dive
    cloc

    # Secrets management
    sops
    age
    bitwarden-cli

    # Media CLI
    ffmpeg

    # Fish greeting
    fortune
    cowsay
    lolcat
  ];

  xdg.configFile."tmux".source = dotfiles.link "tmux";
}
