{ pkgs, ... }:

{
  # Steam with Proton support
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;

    # GE-Proton for better game compatibility
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];

    # Extra packages available in Steam's FHS environment
    package = pkgs.steam.override {
      extraPkgs =
        pkgs': with pkgs'; [
          # Xorg libraries for gamescope/games
          xorg.libXcursor
          xorg.libXi
          xorg.libXinerama
          xorg.libXScrnSaver
          # Audio/media
          libpng
          libpulseaudio
          libvorbis
          # Misc
          stdenv.cc.cc.lib
          libkrb5
          keyutils
        ];
    };
  };

  # Gamemode - automatic CPU/GPU optimizations when gaming
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      # GPU optimizations disabled for NVIDIA hybrid (use nvidia-offload instead)
      # gpu = {
      #   apply_gpu_optimisations = "accept-responsibility";
      #   gpu_device = 0;
      # };
    };
  };

  # Gamescope - micro compositor for better fullscreen/upscaling
  programs.gamescope = {
    enable = true;
    capSysNice = true; # Allow nice level adjustments
  };

  # Gamemode uses nvidia-offload automatically
  environment.sessionVariables = {
    GAMEMODERUNEXEC = "nvidia-offload";
    __GL_MaxFramesAllowed = "1"; # Reduce NVIDIA pre-rendered frame queue for lower input lag
  };

  # Gaming-related packages
  environment.systemPackages = with pkgs; [
    # Proton version manager
    protonup-qt

    # Game launchers (optional, uncomment if needed)
    # lutris
    # heroic  # Epic/GOG launcher
  ];

  # Allow Steam hardware (controllers, VR)
  hardware.steam-hardware.enable = true;
}
