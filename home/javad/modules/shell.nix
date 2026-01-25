{ dotfiles, pkgs, ... }:

{
  home.packages = [ pkgs.fish ];
  xdg.configFile."fish".source = dotfiles.link "fish";

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

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

  programs.bat = {
    enable = true;
    config.theme = "base16";
  };

  programs.fzf.enable = true;
}
