{ pkgs, ... }:

let
  baseApp = {
    alwaysUpdateLinks = true;
    showLineNumber = true;
    spellcheck = true;
    vimMode = false;
    livePreview = true;
  };
in
{
  programs.obsidian = {
    enable = true;

    defaultSettings = {
      app = baseApp;

      corePlugins = [
        "backlink"
        "bookmarks"
        "canvas"
        "command-palette"
        "daily-notes"
        "editor-status"
        "file-explorer"
        "file-recovery"
        "global-search"
        "graph"
        "note-composer"
        "outgoing-link"
        "outline"
        "page-preview"
        "properties"
        "switcher"
        "tag-pane"
        "templates"
        "word-count"
      ];
    };

    vaults."Documents/notes" = {
      enable = true;
      settings.communityPlugins = with pkgs.obsidianPlugins; [
        obsidian-excalidraw-plugin
      ];
    };

    vaults."Dev/simplyprint-client/docs" = {
      enable = true;
      settings.app = baseApp // {
        useMarkdownLinks = true;
        attachmentFolderPath = "attachments";
      };
    };
  };
}
