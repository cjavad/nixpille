# Security hardening
{ ... }:

{
  security = {
    protectKernelImage = true;
    polkit.enable = true;
    sudo.enable = false;
    sudo-rs = {
      enable = true;
      execWheelOnly = true;
      extraConfig = ''
        Defaults !lecture
        Defaults timestamp_timeout=30
      '';
    };
  };
}
