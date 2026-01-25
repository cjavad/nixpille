{ dotfiles, pkgs, ... }:

{
  home.packages = with pkgs; [
    kubectl
    krew
    helm
    helmfile
    kustomize
    k9s
    cloudflared
    trivy
    act
  ];

  home.sessionPath = [ "$HOME/.krew/bin" ];

  xdg.configFile."k9s".source = dotfiles.link "k9s";
}
