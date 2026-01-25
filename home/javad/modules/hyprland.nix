{ dotfiles, pkgs, ... }:

{
  xdg.configFile."hypr".source = dotfiles.link "hypr";
  xdg.configFile."waybar".source = dotfiles.link "waybar";
  xdg.configFile."kitty".source = dotfiles.link "kitty";
  xdg.configFile."mako".source = dotfiles.link "mako";

  home.packages = with pkgs; [
    waybar
    kitty
    mako
    libnotify
    grim
    slurp
    wl-clipboard
    pamixer
  ];

  home.pointerCursor = {
    name = "capitaine-cursors";
    package = pkgs.capitaine-cursors;
    size = 24;
    gtk.enable = true;
  };
}
