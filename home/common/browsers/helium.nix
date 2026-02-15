{
  config,
  pkgs,
  ...
}:

let
  vicinae-nmh-chromium = pkgs.writeTextDir "etc/chromium/native-messaging-hosts/com.vicinae.vicinae.json" (
    builtins.toJSON {
      name = "com.vicinae.vicinae";
      description = "Vicinae Native Messaging Host";
      path = "${config.services.vicinae.package}/libexec/vicinae/vicinae-browser-link";
      type = "stdio";
      # TODO: Load the vicinae chrome extension in Helium, then replace
      # the ID below with the one shown at helium://extensions
      allowed_origins = [ "chrome-extension://aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/" ];
    }
  );
in
{
  programs.helium = {
    enable = true;
    nativeMessagingHosts = [ vicinae-nmh-chromium ];
    commandLineArgs = [
      "--ozone-platform-hint=auto"
      "--enable-features=WaylandWindowDecorations"
      "--enable-wayland-ime=true"
    ];
    extensions = [
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
    ];
  };
}
