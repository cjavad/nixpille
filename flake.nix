{
  description = "NixOS configuration";

  # NOTE: Must be literal values (flake parser limitation)
  # Source of truth: modules/cache/default.nix
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://vicinae.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae.url = "github:vicinaehq/vicinae";
    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    stylix = {
      url = "github:danth/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      flake-parts,
      home-manager,
      ...
    }:
    let
      lib = nixpkgs.lib;

      discover =
        dir:
        lib.filterAttrs (
          name: type:
          type == "directory" && name != "common" && builtins.pathExists (dir + "/${name}/default.nix")
        ) (builtins.readDir dir);

      users = builtins.attrNames (discover ./home);
      hosts = builtins.attrNames (discover ./hosts);

      system = "x86_64-linux";

      pkgs-unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      specialArgs = {
        inherit inputs pkgs-unstable;
      };

      homeModules = [
        inputs.sops-nix.homeManagerModules.sops
        inputs.zen-browser.homeModules.default
      ];

      mkHome =
        user:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = specialArgs;
          modules = homeModules ++ [ ./home/${user}/home.nix ];
        };

      mkHomeModule = userList: {
        imports = [ home-manager.nixosModules.home-manager ];
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          sharedModules = homeModules;
          extraSpecialArgs = specialArgs;
          users = lib.genAttrs userList (user: import ./home/${user}/home.nix);
        };
      };

      mkHost =
        name:
        {
          users ? [ "javad" ],
          desktop ? true,
        }:
        nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            ./hosts/${name}
            ./hosts/common
            inputs.stylix.nixosModules.stylix
          ]
          ++ lib.optional desktop ./hosts/common/desktop.nix
          ++ map (user: ./home/${user}/default.nix) users
          ++ [ (mkHomeModule users) ];
        };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      flake = {
        homeConfigurations = lib.genAttrs users mkHome;

        nixosConfigurations =
          let
            hostConfigs = lib.genAttrs hosts (name: mkHost name { });
            # Hosts to include in full ISO (exclude CI-only hosts)
            isoHosts = lib.filter (name: name != "gha") hosts;
          in
          hostConfigs
          // {
            # Full ISO with all host closures for offline install
            iso = nixpkgs.lib.nixosSystem {
              inherit system specialArgs;
              modules = [
                ./modules/profiles/iso
                (
                  { pkgs, lib, ... }:
                  let
                    hostClosures = builtins.listToAttrs (
                      map (name: {
                        inherit name;
                        value = hostConfigs.${name}.config.system.build.toplevel;
                      }) isoHosts
                    );
                    # Static estimates (GB) - conservative values
                    closureSizes = pkgs.runCommand "closure-sizes" { } ''
                      mkdir -p $out
                      ${lib.concatStringsSep "\n" (map (name: "echo 35 > $out/${name}") isoHosts)}
                    '';
                  in
                  {
                    isoImage.storeContents = lib.attrValues hostClosures;
                    environment.etc."nixpille/closure-sizes".source = closureSizes;
                  }
                )
              ];
            };
            # Minimal ISO for quick testing (no host closures)
            iso-minimal = nixpkgs.lib.nixosSystem {
              inherit system specialArgs;
              modules = [ ./modules/profiles/iso ];
            };
          };
      };

      perSystem =
        { pkgs, self', ... }:
        {
          formatter = pkgs.nixfmt-tree;
          checks = import ./ops/tests {
            inherit pkgs;
            self = inputs.self;
          };
        };
    };
}
