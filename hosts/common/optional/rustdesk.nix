{ pkgs-unstable, ... }:
{
  environment.systemPackages = [ pkgs-unstable.rustdesk-flutter ];
}
