{ pkgs, ... }:

{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.systemPackages = [ pkgs.pulseaudio ]; # for pactl

  security.rtkit.enable = true;
}
