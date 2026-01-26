{
  lib,
  stdenvNoCC,
  fish,
  makeWrapper,
  bitwarden-cli,
  libsecret,
  jq,
  coreutils,
  gnupg,
  openssh,
  pinentry-qt,
  findutils,
}:

stdenvNoCC.mkDerivation {
  pname = "secrets-cli";
  version = "2.0.0";

  src = ./src;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
        runHook preInstall

        # Install Fish scripts
        mkdir -p $out/share/secrets-cli
        cp -r . $out/share/secrets-cli/

        # Create wrapper script
        mkdir -p $out/bin
        cat > $out/bin/secrets << 'WRAPPER'
    #!/usr/bin/env fish
    set -gx SECRETS_LIB_DIR @out@/share/secrets-cli
    source $SECRETS_LIB_DIR/secrets $argv
    WRAPPER

        substituteInPlace $out/bin/secrets --replace-fail '@out@' "$out"
        chmod +x $out/bin/secrets

        # Wrap with dependencies in PATH
        wrapProgram $out/bin/secrets \
          --prefix PATH : ${
            lib.makeBinPath [
              fish
              bitwarden-cli
              libsecret
              jq
              coreutils
              gnupg
              openssh
              pinentry-qt
              findutils
            ]
          }

        runHook postInstall
  '';

  meta = with lib; {
    description = "Secrets management CLI via Bitwarden and GNOME Keyring";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "secrets";
  };
}
