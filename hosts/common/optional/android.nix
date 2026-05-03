{ pkgs, lib, ... }:

let
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    cmdLineToolsVersion = "13.0";
    platformToolsVersion = "35.0.1";
    buildToolsVersions = [ "35.0.0" ];
    platformVersions = [ "35" ];
    abiVersions = [ "x86_64" ];
    includeEmulator = true;
    includeSystemImages = true;
    systemImageTypes = [ "google_apis_playstore" ];
    extraLicenses = [
      "android-googletv-license"
      "android-sdk-arm-dbt-license"
      "android-sdk-license"
      "android-sdk-preview-license"
      "google-gdk-license"
      "intel-android-extra-license"
      "intel-android-sysimage-license"
      "mips-android-sysimage-license"
    ];
  };

  androidSdk = androidComposition.androidsdk;
in
{
  nixpkgs.config.android_sdk.accept_license = true;

  programs.adb.enable = true;

  environment.systemPackages = [
    androidSdk
    pkgs.flutter
    pkgs.jdk17
    pkgs.scrcpy
  ];

  environment.variables = {
    ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
    JAVA_HOME = "${pkgs.jdk17}";
    ANDROID_AVD_HOME = "$HOME/.config/.android/avd";
  };

  environment.sessionVariables = {
    LD_LIBRARY_PATH = lib.makeLibraryPath [
      pkgs.vulkan-loader
      pkgs.libGL
    ];
  };
}
