{ dotfiles, pkgs, ... }:

{
  # Fish - install package, use dotfiles for config
  home.packages = [ pkgs.fish ];
  xdg.configFile."fish".source = dotfiles.link "fish";

  # Direnv - keep nix (no config file needed)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$nix_shell$character";

      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
      };

      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
      };

      git_branch = {
        symbol = " ";
        style = "bold purple";
      };

      nix_shell = {
        symbol = " ";
        format = "[$symbol$state]($style) ";
      };
    };
  };

  # Bat - keep nix (simple one-liner)
  programs.bat = {
    enable = true;
    config.theme = "base16";
  };

  # FZF - just enable, fish plugin handles config
  programs.fzf.enable = true;
}
