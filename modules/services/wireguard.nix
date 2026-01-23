# WireGuard tools only - configs managed via UI (nm-applet/nmtui)
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ wireguard-tools ];

  # NetworkManager handles WireGuard connections
  # Import configs via: nmcli connection import type wireguard file <config>.conf
}
