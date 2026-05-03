{
  lib,
  pkgs,
  pkgs-unstable,
  llm-agents,
  ...
}:


{
  home.packages = [
    llm-agents.claude-code
    llm-agents.codex
    llm-agents.pi
    llm-agents.opencode
  ];
}
