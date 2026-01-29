{
  pkgs,
  inputs,
  lib,
  ...
}:

let
  # Shared VM options for all JetBrains IDEs
  vmopts = ''
    # Memory settings
    -Xms512m
    -Xmx8g
    -XX:ReservedCodeCacheSize=512m

    # GC settings
    -XX:+UseG1GC
    -XX:SoftRefLRUPolicyMSPerMB=50
    -XX:CICompilerCount=2
    -XX:+HeapDumpOnOutOfMemoryError
    -XX:-OmitStackTraceInFastThrow

    # Wayland native support
    -Dawt.toolkit.name=WLToolkit

    # Performance tweaks
    -Dsun.java2d.opengl=true
    -Djdk.attach.allowAttachSelf=true
    -Djdk.module.illegalAccess.silent=true
    -Dkotlinx.coroutines.debug=off

    # Error logging
    -XX:ErrorFile=$USER_HOME/java_error_in_jetbrains_%p.log
    -XX:HeapDumpPath=$USER_HOME/java_error_in_jetbrains.hprof
  '';

  # Helper to create IDE with plugins
  mkIde =
    ide: plugins:
    let
      base = ide.override { inherit vmopts; };
    in
    if plugins == [ ] then base else pkgs.jetbrains.plugins.addPlugins base plugins;

  # Resolve plugins from nix-jetbrains-plugins flake (for plugins not in nixpkgs)
  flakePlugins =
    ide: pluginIds: lib.attrValues (inputs.nix-jetbrains-plugins.lib.pluginsForIde pkgs ide pluginIds);

  # Common plugins for all IDEs
  commonPlugins = [
    "ideavim"
    "vscode-keymap"
    "github-copilot--your-ai-pair-programmer"
    "catppuccin-theme"
    "catppuccin-icons"
  ];

  # PHPStorm-specific plugins available in nixpkgs
  phpstormPlugins = [
    "symfony-plugin"
    "php-annotations"
  ];

  # PHPStorm-specific plugins only available via flake (marketplace IDs)
  phpstormFlakePlugins = [
    "dev.blachut.svelte.lang"
    "com.jetbrains.php.dql"
    "de.espend.idea.php.toolbox"
  ];
in
{
  home.packages = [
    (mkIde pkgs.jetbrains.phpstorm (
      commonPlugins ++ phpstormPlugins ++ flakePlugins pkgs.jetbrains.phpstorm phpstormFlakePlugins
    ))
    (mkIde pkgs.jetbrains.pycharm commonPlugins)
  ];
}
