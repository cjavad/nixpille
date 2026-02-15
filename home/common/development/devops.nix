{ pkgs, ... }:

{
  home.packages = with pkgs; [
    kubectl
    clusterctl
    krew
    kubernetes-helm
    helmfile
    kustomize
    k9s
    cloudflared
    trivy
    act
  ];

  home.sessionPath = [ "$HOME/.krew/bin" ];

  # k9s aliases only (config is default)
  xdg.configFile."k9s/aliases.yaml".text = ''
    aliases:
      dp: deployments
      sec: v1/secrets
      jo: jobs
      cr: clusterroles
      crb: clusterrolebindings
      ro: roles
      rb: rolebindings
      np: networkpolicies
  '';
}
