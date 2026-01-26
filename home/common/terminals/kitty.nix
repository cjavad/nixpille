{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;

    # Stylix handles colors and opacity automatically
    settings = {
      # Window
      window_padding_width = 8;
      confirm_os_window_close = 0;

      # Scrollback
      scrollback_lines = 10000;

      # URLs
      url_style = "curly";
      detect_urls = true;

      # Bell
      enable_audio_bell = false;
      visual_bell_duration = "0.0";

      # Tab bar
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";

      # Cursor
      cursor_shape = "beam";
      cursor_beam_thickness = "1.5";
      cursor_blink_interval = "0.5";

      # Mouse
      mouse_hide_wait = "3.0";
      copy_on_select = "clipboard";

      # Performance
      repaint_delay = 10;
      input_delay = 3;
      sync_to_monitor = true;
    };

    keybindings = {
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      "ctrl+shift+t" = "new_tab";
      "ctrl+shift+w" = "close_tab";
      "ctrl+shift+right" = "next_tab";
      "ctrl+shift+left" = "previous_tab";
      "ctrl+shift+plus" = "change_font_size +1";
      "ctrl+shift+minus" = "change_font_size -1";
      "ctrl+shift+backspace" = "change_font_size 0";
    };
  };
}
