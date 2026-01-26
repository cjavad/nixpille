{ pkgs, ... }:

let
  mkPhp =
    phpPkg: extensions:
    phpPkg.buildEnv {
      extensions = { enabled, all }: enabled ++ (map (e: all.${e}) extensions);
      extraConfig = ''
        memory_limit = 512M
        xdebug.mode = debug,develop
        xdebug.start_with_request = trigger
      '';
    };

  defaultExtensions = [
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
in
{
  home.packages = [
    (mkPhp pkgs.php84 defaultExtensions)
    pkgs.php84Packages.composer
  ];
}
