{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";
    vicinae.url = "github:vicinaehq/vicinae";
    zen-browser.url = "github:youwen5/zen-browser-flake";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      home-manager,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      flake =
        let
          primaryUser = "javad";

          mkHost =
            hostPath:
            nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = {
                inherit inputs primaryUser;
              };
              modules = [
                hostPath
                ./modules/core
                ./modules/dev/docker.nix
                ./modules/desktop/hyprland.nix
                ./modules/desktop/sddm.nix
                ./modules/desktop/flatpak.nix
                ./modules/services/wireguard.nix

                inputs.sops-nix.nixosModules.sops
                (
                  { config, ... }:
                  let
                    home = config.users.users.${primaryUser}.home;
                  in
                  {
                    sops.defaultSopsFile = "${home}/.config/sops/secrets.yaml";
                    sops.age.keyFile = "${home}/.config/sops/age/keys.txt";
                    sops.validateSopsFiles = false; # secrets file is outside repo
                  }
                )
                ./modules/secrets/ssh.nix
                ./modules/secrets/gpg.nix
                ./modules/secrets/kubernetes.nix

                home-manager.nixosModules.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.extraSpecialArgs = { inherit inputs primaryUser; };
                  home-manager.users.${primaryUser} = import ./home/${primaryUser}.nix;
                }
              ];
            };
        in
        {
          nixosConfigurations = {
            vm = mkHost ./hosts/vm;
            ideapad = mkHost ./hosts/ideapad;
            p1gen8 = mkHost ./hosts/p1gen8;

            gha = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = { inherit inputs; };
              modules = [ ./hosts/gha ];
            };

            iso = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = { inherit inputs; };
              modules = [
                "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
                (
                  { pkgs, lib, ... }:
                  {
                    boot.supportedFilesystems.zfs = lib.mkForce false;
                    boot.kernelPackages = pkgs.linuxPackages_latest;
                    isoImage.squashfsCompression = "gzip -Xcompression-level 1";
                    environment.systemPackages = with pkgs; [
                      git
                      vim
                    ];
                    nixpkgs.config.allowUnfree = true;
                  }
                )
              ];
            };
          };
        };

      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt-tree;
          checks = import ./tests { inherit pkgs self; };
        };
    };
}
