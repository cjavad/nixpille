{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
  };

  home.packages = with pkgs; [
    zed-editor
  ];

  xdg.configFile."codebook/codebook.toml".text = ''
    dictionaries = ["en_us"]
    words = []
    ignore_paths = ["node_modules", ".git", "result", "*.lock"]
  '';

  xdg.configFile."zed/settings.json".text = builtins.toJSON {
    icon_theme = {
      mode = "dark";
      light = "Zed (Default)";
      dark = "Zed (Default)";
    };
    ui_font_size = 16;
    buffer_font_size = 15;
    theme = {
      mode = "light";
      light = "Ayu Dark";
      dark = "One Dark";
    };
  };
}
