{ config, inputs, ... }:

let
  localPatchDir = "${inputs.self}/patches/nvidia";
  localPatches =
    if builtins.pathExists localPatchDir then
      let
        files = builtins.attrNames (builtins.readDir localPatchDir);
        patchFiles = builtins.filter (f: builtins.match ".*\\.patch" f != null) files;
      in
      map (f: "${localPatchDir}/${f}") patchFiles
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
          patches = openOld.patches ++ localPatches;
        });
      };
    });
  };

  services.xserver.videoDrivers = [ "nvidia" ];
}
