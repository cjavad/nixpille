{
  description = "NixOS configuration";

  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://vicinae.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+VO9dXvamGIBD/FX5BsGNN7CQ56MWRspLU="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
    ];
  };

  inputs = {
    # Stable by default
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";
    vicinae.url = "github:vicinaehq/vicinae/v0.19.1";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
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
          lib = nixpkgs.lib;

          # Unstable packages for selective use
          pkgs-unstable = import inputs.nixpkgs-unstable {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };

          # Home-manager configuration for a list of users
          mkHomeManagerUsers = users: {
            imports = [ home-manager.nixosModules.home-manager ];
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              sharedModules = [
                inputs.sops-nix.homeManagerModules.sops
                inputs.zen-browser.homeModules.default
              ];
              extraSpecialArgs = {
                inherit inputs pkgs-unstable;
              };
              users = lib.genAttrs users (user: import ./users/${user}/home.nix);
            };
          };

          # Build a host configuration
          mkHost =
            {
              hostPath,
              users ? [ "javad" ],
              desktop ? true,
            }:
            nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = {
                inherit inputs pkgs-unstable;
              };
              modules = [
                hostPath
              ]
              ++ [ ./hosts/common ]
              ++ lib.optionals desktop [ ./hosts/common/desktop.nix ]
              ++ map (user: ./users/${user}/default.nix) users
              ++ [ (mkHomeManagerUsers users) ];
            };

          # Auto-discover hosts from hosts/ directory
          # Each subdirectory with a default.nix becomes a host
          hostDirs = builtins.readDir ./hosts;

          isHostDir =
            name: type:
            type == "directory" && name != "common" && builtins.pathExists (./hosts + "/${name}/default.nix");

          discoveredHosts = lib.filterAttrs isHostDir hostDirs;

          # Generate nixosConfigurations for each discovered host
          autoHosts = lib.mapAttrs (
            name: _:
            mkHost {
              hostPath = ./hosts + "/${name}";
              users = [ "javad" ];
            }
          ) discoveredHosts;

        in
        {
          homeConfigurations = {
            javad = home-manager.lib.homeManagerConfiguration {
              pkgs = nixpkgs.legacyPackages.x86_64-linux;
              extraSpecialArgs = {
                inherit inputs pkgs-unstable;
              };
              modules = [
                inputs.sops-nix.homeManagerModules.sops
                inputs.zen-browser.homeModules.default
                ./users/javad/home.nix
              ];
            };
          };

          # Auto-discovered hosts + special configs
          nixosConfigurations = autoHosts // {
            # ISO installer (not a regular host)
            iso = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = {
                inherit inputs pkgs-unstable;
              };
              modules = [ ./modules/profiles/iso ];
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
