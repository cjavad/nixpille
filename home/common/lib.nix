{ config, ... }:

let
  username = config.home.username;
  repoPath = "${config.home.homeDirectory}/Dev/nixpille";
  dotfilesPath = "${repoPath}/home/${username}/dotfiles";
in
{
  _module.args.dotfiles = {
    path = dotfilesPath;
    link = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${path}";
  };
}
