{ dotfiles, pkgs, ... }:

{
  home.packages = with pkgs; [
    git
    vim
    curl
    unzip
    fd
    ripgrep
    bat
    eza
    tree
    jq
    yq-go
    htop
    btop
    fastfetch
    tmux
    zellij
    go-task
    dive
    cloc
    sops
    age
    bitwarden-cli
    wireguard-tools
    ffmpeg
    fortune
    cowsay
    lolcat
  ];

  xdg.configFile."tmux".source = dotfiles.link "tmux";
}
