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
  mkIde = ide: plugins:
    let
      base = ide.override { inherit vmopts; };
    in
    if plugins == [ ]
    then base
    else pkgs.jetbrains.plugins.addPlugins base plugins;

  # Common plugins for all IDEs (add plugin IDs from JetBrains Marketplace)
  commonPlugins = [
    # "com.intellij.plugins.watcher"  # File Watchers
  ];
in
{
  home.packages = [
    (mkIde pkgs.jetbrains.phpstorm commonPlugins)
    (mkIde pkgs.jetbrains.pycharm commonPlugins)
  ];
}
