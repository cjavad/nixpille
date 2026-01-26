{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  bash,
  jq,
  socat,
}:

stdenvNoCC.mkDerivation {
  pname = "hyproled";
  version = "unstable-2024-10-15";

  src = fetchFromGitHub {
    owner = "mklan";
    repo = "hyproled";
    rev = "886c5094a2217ca196c9476a5a64dee6c2bb2876";
    hash = "sha256-XiGotF3lss83LP2zgk04Ss1ciVBoNPe9FIFFdOqYGXs=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp hyproled $out/bin/
    chmod +x $out/bin/hyproled
    wrapProgram $out/bin/hyproled \
      --prefix PATH : ${
        lib.makeBinPath [
          bash
          jq
          socat
        ]
      }
    runHook postInstall
  '';

  meta = with lib; {
    description = "Hyprland shader to prevent OLED burn-in";
    homepage = "https://github.com/mklan/hyproled";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "hyproled";
  };
}
