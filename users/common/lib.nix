# Shared helpers for home-manager modules
# Provides: dotfiles.link and dotfiles.path via _module.args
{ config, ... }:

let
  username = config.home.username;
  # Dotfiles in repo: users/<username>/dotfiles/
  repoPath = "${config.home.homeDirectory}/Dev/nixpille";
  dotfilesPath = "${repoPath}/users/${username}/dotfiles";
in
{
  _module.args.dotfiles = {
    path = dotfilesPath;
    link = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${path}";
  };
}
