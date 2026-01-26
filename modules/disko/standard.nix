{
  device ? "/dev/nvme0n1",
  sectorSize ? 4096,
  ...
}:
let
  btrfsMountOptions = [
    "defaults"
    "noatime"
    "compress=zstd:1"
    "ssd"
    "discard=async"
    "space_cache=v2"
  ];
in
{
  disko.devices = {
    disk.main = {
      type = "disk";
      inherit device;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "fmask=0077"
                "dmask=0077"
                "noatime"
              ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [
                "-f"
                "--sectorsize"
                (toString sectorSize)
              ];
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = btrfsMountOptions;
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = btrfsMountOptions;
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = btrfsMountOptions ++ [ "nodev" ];
                };
                "@log" = {
                  mountpoint = "/var/log";
                  mountOptions = btrfsMountOptions ++ [
                    "nodev"
                    "nosuid"
                    "noexec"
                  ];
                };
                "@snapshots" = {
                  mountpoint = "/.snapshots";
                  mountOptions = btrfsMountOptions ++ [
                    "nodev"
                    "nosuid"
                    "noexec"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };
}
