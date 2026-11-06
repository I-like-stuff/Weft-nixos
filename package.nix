{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeBinaryWrapper
, copyDesktopItems
, makeDesktopItem
, vulkan-loader
, libxkbcommon
, wayland
, libx11
, libxcursor
, libxrandr
, libxi
, libxinerama
, libGL
, alsa-lib
}:

let
  source = lib.importJSON ./source.json;
  runtimeLibs = [
    vulkan-loader
    libxkbcommon
    wayland
    libx11
    libxcursor
    libxrandr
    libxi
    libxinerama
    alsa-lib
    libGL
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "weft";
  inherit (source) version;

  src = fetchurl {
    inherit (source) url hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    makeBinaryWrapper
    copyDesktopItems
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ] ++ runtimeLibs;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/weft $out/bin
    WEFT_BIN=$(find . -name weft -type f -perm -111 | head -n 1)
    EXTRACT_DIR=$(dirname "$WEFT_BIN")

    cp -r "$EXTRACT_DIR"/* $out/share/weft/
    chmod +x $out/share/weft/weft

    makeBinaryWrapper $out/share/weft/weft $out/bin/weft \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}:$out/share/weft"

    if [ -f $out/share/weft/mods/base/assets/textures/gui/icon.png ]; then
      install -Dm644 $out/share/weft/mods/base/assets/textures/gui/icon.png $out/share/pixmaps/weft.png
    fi

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "weft";
      exec = "weft";
      icon = "weft";
      comment = "Voxel sandbox engine written in Rust";
      desktopName = "Weft";
      genericName = "Voxel Sandbox Game";
      categories = [ "Game" "Simulation" ];
      keywords = [ "voxel" "sandbox" "minecraft" ];
    })
  ];

  meta = with lib; {
    description = "Voxel sandbox engine (precompiled release)";
    homepage = "https://github.com/weft-rust/weft";
    license = licenses.mpl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "weft";
  };
})
