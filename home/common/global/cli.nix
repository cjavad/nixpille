{ pkgs, ... }:

{
  home.packages = with pkgs; [
    git
    neovim
    curl
    unzip
    fd
    ripgrep
    tree
    jq
    yq-go
    htop
    btop
    fastfetch
    zellij
    go-task
    dive
    cloc
    sops
    age
    wireguard-tools
    ffmpeg
    fortune
    cowsay
    lolcat
  ];

  programs.tmux = {
    enable = true;
    mouse = true;
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 10000;
    keyMode = "vi";
    terminal = "tmux-256color";

    extraConfig = ''
      # True color support
      set -ag terminal-overrides ",xterm-256color:RGB"

      # Renumber windows on close
      set -g renumber-windows on

      # Pane base index
      setw -g pane-base-index 1

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded"

      # Split panes with | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Vi copy mode
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi y send -X copy-selection-and-cancel

      # Pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Status bar (Stylix will override colors)
      set -g status-left ""
      set -g status-right "%H:%M"
    '';
  };
}
