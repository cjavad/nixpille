{ dotfiles, pkgs, ... }:

{
  # Dotfiles - symlink to repo (mutable, editable directly)
  xdg.configFile."hypr".source = dotfiles.link "hypr";
  xdg.configFile."waybar".source = dotfiles.link "waybar";
  xdg.configFile."kitty".source = dotfiles.link "kitty";
  xdg.configFile."mako".source = dotfiles.link "mako";

  # Packages only - config comes from dotfiles
  home.packages = with pkgs; [
    waybar
    kitty
    mako
    libnotify
  ];

  home.pointerCursor = {
    name = "capitaine-cursors";
    package = pkgs.capitaine-cursors;
    size = 24;
    gtk.enable = true;
  };
}
