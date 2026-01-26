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

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Blue light filter (has flake.nix)
    sunsetr = {
      url = "github:psi4j/sunsetr";
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

      # Custom packages overlay
      customOverlay = final: prev: {
        custom = import ./pkgs { pkgs = final; };
      };

      # Discover directories with default.nix (excluding "common")
      discover =
        dir:
        lib.filterAttrs (
          name: type:
          type == "directory" && name != "common" && builtins.pathExists (dir + "/${name}/default.nix")
        ) (builtins.readDir dir);

      # Discover directories (excluding "common")
      discoverDirs =
        dir: lib.filterAttrs (name: type: type == "directory" && name != "common") (builtins.readDir dir);

      hosts = builtins.attrNames (discover ./hosts);
      users = builtins.attrNames (discoverDirs ./home);

      system = "x86_64-linux";

      pkgs-unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      specialArgs = {
        inherit inputs pkgs-unstable;
        flakeRoot = ./.;
      };

      # Home-manager shared modules
      # Note: stylix is auto-configured via NixOS module, don't add here
      homeModules = [
        inputs.zen-browser.homeModules.default
      ];

      # Home-manager NixOS module with shared config
      homeManagerModule = {
        imports = [ home-manager.nixosModules.home-manager ];
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          sharedModules = homeModules;
          extraSpecialArgs = specialArgs;
        };
      };

      mkHost =
        name:
        nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules = [
            { nixpkgs.overlays = [ customOverlay ]; }
            ./hosts/${name}
            inputs.stylix.nixosModules.stylix
            homeManagerModule
          ];
        };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      flake = {
        nixosConfigurations =
          let
            hostConfigs = lib.genAttrs hosts mkHost;
          in
          hostConfigs
          // {
            # Minimal network installer ISO
            iso = nixpkgs.lib.nixosSystem {
              inherit system specialArgs;
              modules = [ ./modules/profiles/iso ];
            };
          };

        # Export as user@host (e.g., javad@vm) for `home-manager switch --flake /etc/nixos`
        homeConfigurations =
          let
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
              overlays = [ customOverlay ];
            };
            mkHome =
              user: host:
              home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                extraSpecialArgs = specialArgs;
                modules = homeModules ++ [
                  ./home/${user}/${host}
                  inputs.stylix.homeModules.stylix
                  inputs.sops-nix.homeManagerModules.sops
                ];
              };
            # For each user, discover their host configs
            userHosts = lib.listToAttrs (
              lib.flatten (
                map (
                  user:
                  let
                    userHostDirs = builtins.attrNames (discover ./home/${user});
                  in
                  map (host: {
                    name = "${user}@${host}";
                    value = mkHome user host;
                  }) userHostDirs
                ) users
              )
            );
          in
          userHosts;
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
