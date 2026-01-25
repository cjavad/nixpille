{ pkgs, self }:

{
  smoke = pkgs.runCommandLocal "smoke-test" { } ''
    echo "=== nixpille smoke test ==="
    echo "Hello from nixpille!"
    test -d ${self} && echo "OK: flake source exists"
    test -f ${self}/flake.nix && echo "OK: flake.nix exists"
    test -d ${self}/hosts && echo "OK: hosts/ exists"
    test -d ${self}/modules && echo "OK: modules/ exists"
    test -d ${self}/home && echo "OK: home/ exists"
    mkdir -p $out
    echo "ok" > $out/result
  '';
}
