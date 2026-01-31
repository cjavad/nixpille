{
  pkgs-unstable,
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

  # Resolve plugins from nix-jetbrains-plugins flake (marketplace IDs → derivations)
  pluginsFor =
    ide: pluginIds:
    lib.attrValues (inputs.nix-jetbrains-plugins.lib.pluginsForIde pkgs-unstable ide pluginIds);

  # Helper to create IDE with plugins
  mkIde =
    ide: pluginIds:
    let
      base = ide.override { inherit vmopts; };
      plugins = pluginsFor ide pluginIds;
    in
    if pluginIds == [ ] then base else pkgs-unstable.jetbrains.plugins.addPlugins base plugins;

  # Common plugins for all IDEs
  commonPlugins = [
    "IdeaVIM"
    "com.intellij.plugins.vscodekeymap"
    "org.jetbrains.plugins.github"
    "com.github.copilot"
    "com.github.catppuccin.jetbrains"
    "com.github.catppuccin.jetbrains_icons"
    "nix-idea"
  ];

  # PHPStorm-specific plugins
  phpstormPlugins = [
    "dev.blachut.svelte.lang"
    "fr.adrienbrault.idea.symfony2plugin"
    "de.espend.idea.php.annotation"
    "com.jetbrains.php.dql"
    "de.espend.idea.php.toolbox"
  ];

  # CLion-specific plugins
  clionPlugins = [
    "com.jetbrains.rust"
  ];
in
{
  home.packages = [
    (mkIde pkgs-unstable.jetbrains.phpstorm (commonPlugins ++ phpstormPlugins))
    (mkIde pkgs-unstable.jetbrains.clion (commonPlugins ++ clionPlugins))
    (mkIde pkgs-unstable.jetbrains.pycharm commonPlugins)
  ];
}
