#!/usr/bin/env bash
# Runs Godot against this project. The default binary is the Mono build managed by the Godots
# flatpak, which only starts inside that sandbox because the .NET SDK lives there.
# Set GODOT to a host binary to bypass the flatpak.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(git -C "$SKILL_DIR" rev-parse --show-toplevel)"
GODOTS_BIN="$HOME/.var/app/io.github.MakovWait.Godots/data/godot/app_userdata/Godots/versions/Godot_v4_6_2-stable_mono_linux_x86_64/Godot_v4.6.2-stable_mono_linux_x86_64/Godot_v4.6.2-stable_mono_linux.x86_64"

if [[ "${1:-}" == "check" ]]; then
	set -- --headless -s "$SKILL_DIR/check_scripts.gd"
fi

if [[ -n "${GODOT:-}" ]]; then
	exec "$GODOT" --path "$PROJECT_DIR" "$@"
fi

exec flatpak run --filesystem="$SKILL_DIR:ro" --command="$GODOTS_BIN" io.github.MakovWait.Godots \
	--path "$PROJECT_DIR" "$@"
