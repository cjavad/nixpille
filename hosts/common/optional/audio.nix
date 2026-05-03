{ pkgs, ... }:

{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # Low-latency: 256 samples @ 48kHz = ~5.3ms (default is 1024 = ~21ms)
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 256;
        "default.clock.min-quantum" = 256;
        "default.clock.max-quantum" = 1024;
      };
    };

    extraConfig.pipewire-pulse."92-low-latency" = {
      "pulse.properties" = {
        "pulse.min.req" = "256/48000";
        "pulse.default.req" = "256/48000";
        "pulse.max.req" = "256/48000";
        "pulse.min.quantum" = "256/48000";
        "pulse.max.quantum" = "256/48000";
      };
    };
  };

  environment.systemPackages = [ pkgs.pulseaudio ]; # for pactl

  security.rtkit.enable = true;
}
