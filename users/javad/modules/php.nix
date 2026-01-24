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

  # Your extensions (based on current php -m)
  defaultExtensions = [
    # Debug/dev
    "xdebug"
    # Caching
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
    # Internationalization
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
in
{
  home.packages = [
    (mkPhp pkgs.php84 defaultExtensions)
    pkgs.php84Packages.composer
  ];
}
