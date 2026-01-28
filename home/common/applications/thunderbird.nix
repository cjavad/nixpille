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

        # Dark mode / theme
        "ui.systemUsesDarkTheme" = 1;
        "browser.display.use_system_colors" = false;
        "layout.css.prefers-color-scheme.content-override" = 0; # 0 = dark
        "browser.in-content.dark-mode" = true;
        "extensions.activeThemeID" = "thunderbird-compact-dark@mozilla.org";

        # Clean UI
        "mail.pane_config.dynamic" = 2; # Vertical view (modern layout)
        "mailnews.default_view_flags" = 1; # Threaded view
        "mail.showCondensedAddresses" = true;
        "mailnews.table_layout.version" = 1;
        "mail.uifontsize" = 14;
        "browser.display.background_color" = "#1e1e2e";
        "browser.display.foreground_color" = "#cdd6f4";
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
