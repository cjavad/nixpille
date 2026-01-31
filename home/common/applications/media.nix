{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nautilus # File manager
    file-roller # Archive manager (Nautilus integration)
    loupe # Images (GTK4, GNOME)
    papers # PDFs, EPUB, DjVu (GTK4, GNOME)
    mpv # Video & audio
  ];
}
