{
  pkgs ? import <nixpkgs> { },
}:

let
  phpPkg = pkgs.php84;

  extensions = [
    "xdebug"
    "redis"
    "igbinary"
    "opcache"
    "pdo_mysql"
    "pdo_pgsql"
    "pdo_sqlite"
    "mysqli"
    "gd"
    "imagick"
    "zip"
    "bz2"
    "intl"
    "mbstring"
    "soap"
    "xml"
    "xsl"
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
