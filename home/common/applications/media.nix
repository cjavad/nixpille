{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nautilus # File manager
    file-roller # Archive manager (Nautilus integration)
    loupe # Images (GTK4, GNOME)
    papers # PDFs, EPUB, DjVu (GTK4, GNOME)
    mpv # Video & audio
    uxplay # AirPlay receiver (use with OBS window capture)
  ];

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-pipewire-audio-capture # PipeWire audio capture
      wlrobs # Wayland/wlroots screen capture (for Hyprland)
      obs-vkcapture # Vulkan/OpenGL game capture
      obs-gstreamer # GStreamer integration (additional codec support)
    ];
  };
}
