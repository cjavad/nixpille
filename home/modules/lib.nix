# Shared helpers for home-manager modules
# Provides: dotfiles.link and dotfiles.path via _module.args
{ config, ... }:

let
  dotfilesPath = "${config.home.homeDirectory}/.config/nixos-config/dotfiles";
in
{
  _module.args.dotfiles = {
    path = dotfilesPath;
    link = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${path}";
  };
}
