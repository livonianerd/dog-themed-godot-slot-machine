#!/usr/bin/env bash
set -euo pipefail
GODOT_BIN="${GODOT_BIN:-.tools/godot}"
mkdir -p build/web build/windows build/linux build/downloads
touch build/.gdignore
"$GODOT_BIN" --headless --editor --path . --import --quit
"$GODOT_BIN" --headless --path . --script scripts/verify_math.gd
"$GODOT_BIN" --headless --path . --script tests/test_game.gd
"$GODOT_BIN" --headless --path . --script tests/test_ui.gd
"$GODOT_BIN" --headless --path . --export-release Web build/web/index.html
"$GODOT_BIN" --headless --path . --export-release Windows build/windows/dog-slots.exe
"$GODOT_BIN" --headless --path . --export-release Linux build/linux/dog-slots.x86_64
chmod +x build/linux/dog-slots.x86_64
(cd build/windows && zip -q ../downloads/dog-slots-windows.zip *)
(cd build/linux && zip -q ../downloads/dog-slots-linux.zip *)
(cd build/downloads && sha256sum dog-slots-*.zip > SHA256SUMS.txt)
