{
  # Include GitHub token if available (avoids API rate limits)
  # Token is managed by home-manager user service
  nix.extraOptions = ''
    !include /etc/nix/github-token.conf
  '';
}
