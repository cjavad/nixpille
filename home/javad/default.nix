# Home configuration for javad (standalone home-manager)
{
  imports = [
    ../common/global
    ../common/linux-desktop
    ../common/development
    ../common/applications
    ./secrets.nix
  ];
}
