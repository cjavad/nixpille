{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Rust
    rustup

    # Go
    go
    gopls
    delve
    golangci-lint

    # Python
    python313
    uv

    # Node
    nodejs_22
    bun
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
