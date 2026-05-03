{ config, pkgs, ... }:

{
  programs.fish = {
    enable = true;

    shellInit = ''
      # Environment variables
      set -gx EDITOR nvim
      set -gx VISUAL nvim
      set -gx PAGER less
      set -gx LESS '-g -i -M -R -S -w -X -z-4'
      set -gx XCURSOR_THEME 'capitaine-cursors'
      set -gx XCURSOR_SIZE 24
      set -gx DOCKER_HOST "unix:///run/user/"(id -u)"/podman/podman.sock"
      set -gx CLAUDE_CODE_DISABLE_AUTO_MEMORY 1

      # Basic functions
      function spawn; $argv > /dev/null 2>&1 &; disown; end
      function blackout --description "Clears screen, hides cursor and prompts"
          function fish_prompt; printf '\e[?25l'; end
          function fish_right_prompt; end
          function fish_mode_prompt; end
          clear
      end
    '';

    interactiveShellInit = ''
      # Greeting with random cowsay
      function fish_greeting
        fortune | cowsay -f (cowsay -l | tail -n +2 | tr ' ' '\n' | grep . | shuf -n1) | lolcat --seed (math (random 0 1000))
      end

      # Google Cloud SDK
      if [ -f "$HOME/.google-cloud-sdk/path.fish.inc" ]
        . "$HOME/.google-cloud-sdk/path.fish.inc"
      end
    '';

    shellAliases = {
      task = "go-task";
      ssh = "TERM=xterm-256color command ssh";
      nixos-task = "task -d /etc/nixos";
      scrcpy = "scrcpy --render-driver=opengl";
    };

    plugins = [
      # fzf integration (replaces patrickf1/fzf.fish)
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
    ];
  };

  # Paths
  home.sessionPath = [
    "$HOME/.bun/bin"
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
    "/var/lib/flatpak/exports/bin"
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.bat = {
    enable = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = false; # Using fzf-fish plugin
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
  };
}
