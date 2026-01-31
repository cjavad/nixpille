{ ... }:
{
  programs.helium = {
    enable = true;
    commandLineArgs = [
      "--ozone-platform-hint=auto"
      "--enable-features=WaylandWindowDecorations"
      "--enable-wayland-ime=true"
    ];
    extensions = [
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
    ];
  };
}
