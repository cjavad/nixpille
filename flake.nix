{
  description = "NixOS configuration";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://vicinae.cachix.org"
      "https://attic.xuyh0120.win/lantian"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    vicinae.url = "github:vicinaehq/vicinae";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    vicinae-extensions.url = "github:vicinaehq/extensions";
    vicinae-extensions.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix/release-25.11";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    sunsetr.url = "github:psi4j/sunsetr";
    sunsetr.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    helium = {
      url = "github:cjavad/nixpille-helium";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-jetbrains-plugins.url = "github:nix-community/nix-jetbrains-plugins";
  };

  outputs =
    inputs@{
      nixpkgs,
      flake-parts,
      home-manager,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      system = "x86_64-linux";

      # Directory helpers
      readDirs = dir: lib.filterAttrs (_: t: t == "directory") (builtins.readDir dir);
      discover =
        dir:
        lib.attrNames (
          lib.filterAttrs (n: _: n != "common" && builtins.pathExists (dir + "/${n}/default.nix")) (
            readDirs dir
          )
        );

      hosts = discover ./hosts;
      users = lib.attrNames (lib.filterAttrs (n: _: n != "common") (readDirs ./home));

      hasNvidia =
        host:
        builtins.pathExists ./hosts/${host}/nvidia.nix
        || lib.hasInfix "nvidia.nix" (builtins.readFile ./hosts/${host}/default.nix);

      overlaysFor =
        host:
        [
          (final: _: { custom = import ./pkgs { pkgs = final; }; })
          inputs.nix-cachyos-kernel.overlays.pinned
        ]
        ++ lib.optional (hasNvidia host) (import ./overlays/nvidia.nix);

      pkgsFor =
        host:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = overlaysFor host;
        };

      pkgs-unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      pkgs-master = import inputs.nixpkgs-master {
        inherit system;
        config.allowUnfree = true;
      };

      specialArgs = {
        inherit inputs pkgs-unstable pkgs-master;
        flakeRoot = ./.;
      };

      hmModules = [
        inputs.zen-browser.homeModules.beta
        inputs.helium.homeModules.default
        inputs.sops-nix.homeManagerModules.sops
      ];

      mkHost =
        host:
        lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            { nixpkgs.overlays = overlaysFor host; }
            ./hosts/${host}
            inputs.stylix.nixosModules.stylix
            {
              imports = [ home-manager.nixosModules.home-manager ];
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-bak";
                extraSpecialArgs = specialArgs;
                sharedModules = hmModules;
              };
            }
          ];
        };

      mkHome =
        user: host:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor host;
          extraSpecialArgs = specialArgs;
          modules = hmModules ++ [
            inputs.stylix.homeModules.stylix
            ./modules/desktop/stylix.nix
            ./home/${user}/${host}
          ];
        };

      homeEntries = lib.concatMap (
        user: map (host: lib.nameValuePair "${user}@${host}" (mkHome user host)) (discover ./home/${user})
      ) users;

    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      flake = {
        homeModules.secrets = ./modules/home-manager/secrets;

        nixosConfigurations = lib.genAttrs hosts mkHost // {
          iso = lib.nixosSystem {
            inherit system specialArgs;
            modules = [ ./modules/profiles/iso ];
          };
        };

        homeConfigurations = lib.listToAttrs homeEntries;
      };

      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt-tree;
          checks = import ./ops/tests {
            inherit pkgs;
            self = inputs.self;
          };
        };
    };
}
