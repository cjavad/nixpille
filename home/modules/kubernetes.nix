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

  # krew plugins path
  home.sessionPath = [ "$HOME/.krew/bin" ];

  # k9s config from dotfiles (mutable, editable directly)
  xdg.configFile."k9s".source = dotfiles.link "k9s";

  # kubeconfig deployed by sops-nix to ~/.kube/config
}
