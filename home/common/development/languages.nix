{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gcc
    gnumake
    rustup
    go
    gopls
    delve
    golangci-lint
    python313
    uv
    nodejs_22
    bun
    nixd
    nixfmt-rfc-style
  ];

  home.sessionVariables = {
    GOPATH = "$HOME/go";
    CARGO_HOME = "$HOME/.cargo";
    RUSTUP_HOME = "$HOME/.rustup";
  };

  home.sessionPath = [
    "$HOME/go/bin"
    "$HOME/.cargo/bin"
  ];
}
