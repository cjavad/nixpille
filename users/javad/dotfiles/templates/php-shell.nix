# Per-project PHP shell
# Copy to project, change phpPkg version, then: echo "use nix" > .envrc && direnv allow
{
  pkgs ? import <nixpkgs> { },
}:

let
  # Change: php83, php84, php85
  phpPkg = pkgs.php84;

  extensions = [
    # Debug
    "xdebug"
    # Cache
    "redis"
    "igbinary"
    "opcache"
    # Database
    "pdo_mysql"
    "pdo_pgsql"
    "pdo_sqlite"
    "mysqli"
    # Image
    "gd"
    "imagick"
    # Compression
    "zip"
    "bz2"
    # i18n
    "intl"
    "mbstring"
    # XML
    "soap"
    "xml"
    "xsl"
    # Misc
    "bcmath"
    "gmp"
    "ldap"
    "sodium"
    "tidy"
    "sockets"
    "swoole"
    "ds"
  ];

  php = phpPkg.buildEnv {
    extensions = { enabled, all }: enabled ++ (map (e: all.${e}) extensions);
    extraConfig = ''
      memory_limit = 512M
      xdebug.mode = debug,develop
      xdebug.start_with_request = trigger
    '';
  };
in
pkgs.mkShell {
  packages = [
    php
    php.packages.composer
  ];
  shellHook = "echo \"PHP $(php -v | head -1)\"";
}
