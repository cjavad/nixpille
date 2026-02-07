# PC/SC smart card daemon (for NFC readers)
{ pkgs, ... }:

{
  services.pcscd = {
    enable = true;
    plugins = [ pkgs.ccid ];
  };
}
