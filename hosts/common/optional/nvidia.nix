{ config, inputs, lib, ... }:

let
  kernelVersion = config.boot.kernelPackages.kernel.version;
  majorMinor = lib.versions.majorMinor kernelVersion;

  patchDir = "${inputs.cachyos-kernel-patches}/${majorMinor}/misc/nvidia";
  cachyosPatches =
    if builtins.pathExists patchDir then
      let
        files = builtins.attrNames (builtins.readDir patchDir);
        patchFiles = builtins.filter (f: builtins.match ".*\\.patch" f != null) files;
      in
      map (f: "${patchDir}/${f}") patchFiles
    else
      [ ];

  base = config.boot.kernelPackages.nvidiaPackages.stable;
in
{
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    open = true;
    nvidiaSettings = true;
    package = base.overrideAttrs (old: {
      passthru = old.passthru // {
        open = old.passthru.open.overrideAttrs (openOld: {
          patches = openOld.patches ++ cachyosPatches;
        });
      };
    });
  };

  services.xserver.videoDrivers = [ "nvidia" ];
}
