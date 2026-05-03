{ pkgs, lib, ... }:

let
  # Swoole 6.1 with openssl, curl and mysqlnd support
  swoole61 = pkgs.php84Extensions.swoole.overrideAttrs (old: {
    version = "6.1.7";
    src = pkgs.fetchFromGitHub {
      owner = "swoole";
      repo = "swoole-src";
      rev = "v6.1.7";
      hash = "sha256-MY0wWb6p2P+g7xrEGqicvdIbX57vgSFKunKVxj80PgQ=";
    };
    configureFlags = (old.configureFlags or [ ]) ++ [
      "--enable-openssl"
      "--enable-swoole-curl"
      "--enable-mysqlnd"
      "--enable-sockets"
    ];
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.pkg-config ];
    buildInputs = (old.buildInputs or [ ]) ++ [
      pkgs.openssl.dev
      pkgs.curl.dev
    ];
    # buildPecl bakes internalDeps into autoreconfPhase at eval time,
    # so overrideAttrs on internalDeps is too late. Patch the phase directly.
    autoreconfPhase = old.autoreconfPhase + ''
      mkdir -p ext
      ln -s ${pkgs.php84Extensions.sockets.dev}/include ext/sockets
    '';
  });

  php = pkgs.php84.buildEnv {
    extensions =
      { enabled, all }:
      # Filter out explicitly listed extensions from defaults to avoid duplicates
      let
        extraExts = [
          all.xdebug
          all.redis
          all.igbinary
          all.opcache
          all.pdo_mysql
          all.pdo_pgsql
          all.mysqli
          all.gd
          all.imagick
          all.zip
          all.bz2
          all.intl
          all.soap
          all.xsl
          all.bcmath
          all.gmp
          all.ldap
          all.sodium
          all.tidy
          all.sockets
          all.pcntl
          all.ds
          swoole61
        ];
        extraNames = map (e: e.extensionName) extraExts;
      in
      (builtins.filter (e: !(builtins.elem e.extensionName extraNames)) enabled) ++ extraExts;

    extraConfig = ''
      memory_limit = 512M
      xdebug.mode = debug,develop
      xdebug.start_with_request = trigger
    '';
  };
in
{
  home.packages = [
    php
    pkgs.php84Packages.composer
  ];
}
