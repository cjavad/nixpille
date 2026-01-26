{ pkgs, config, ... }:

{
  programs.thunderbird = {
    enable = true;
    profiles.default = {
      isDefault = true;
      settings = {
        # Privacy
        "datareporting.healthreport.uploadEnabled" = false;
        "mailnews.start_page.enabled" = false;
        # Compose
        "mail.identity.default.compose_html" = true;
        "mail.SpellCheckBeforeSend" = false;
      };
    };
  };

  # Account configuration example (uncomment and customize):
  # programs.thunderbird.profiles.default.accounts = {
  #   "Personal" = {
  #     primary = true;
  #     address = "you@example.com";
  #     realName = "Your Name";
  #     imap = {
  #       host = "imap.example.com";
  #       port = 993;
  #       tls.enable = true;
  #     };
  #     smtp = {
  #       host = "smtp.example.com";
  #       port = 587;
  #       tls.enable = true;
  #     };
  #   };
  # };
}
