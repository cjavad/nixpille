{ pkgs }:

{
  hyproled = pkgs.callPackage ./hyproled { };
  secrets-cli = pkgs.callPackage ./secrets-cli { };
}
