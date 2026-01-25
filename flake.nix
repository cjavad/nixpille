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
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
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
          lib = nixpkgs.lib;

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
              extraSpecialArgs = { inherit inputs; };
              users = lib.genAttrs users (user: import ./users/${user}/home.nix);
            };
          };

          mkHost =
            {
              hostPath,
              users,
              desktop ? true,
              dev ? true,
            }:
            nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = { inherit inputs; };
              modules = [
                hostPath
              ]
              ++ [ ./hosts/common ]
              ++ lib.optionals desktop [ ./hosts/common/desktop.nix ]
              ++ lib.optionals dev [ ./hosts/common/development.nix ]
              ++ map (user: ./users/${user}/default.nix) users
              ++ [ (mkHomeManagerUsers users) ];
            };
        in
        {
          nixosConfigurations = {
            vm = mkHost {
              hostPath = ./hosts/vm;
              users = [ "javad" ];
            };
            ideapad = mkHost {
              hostPath = ./hosts/ideapad;
              users = [ "javad" ];
            };
            p1gen8 = mkHost {
              hostPath = ./hosts/p1gen8;
              users = [ "javad" ];
            };

            gha = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = { inherit inputs; };
              modules = [
                ./hosts/gha
                ./users/runner/default.nix
              ];
            };

            iso = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = { inherit inputs; };
              modules = [ ./modules/profiles/iso.nix ];
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
