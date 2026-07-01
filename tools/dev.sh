#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-doctor}"
QUIT_AFTER="${2:-0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PARENT_ROOT="$(cd "$REPO_ROOT/.." && pwd)"
TOOLS_ROOT="${MINIGAME_TOOLS_DIR:-$PARENT_ROOT/tmp/godot}"
GODOT_VERSION="4.6-stable"

case "$(uname -s)" in
  Darwin)
    GODOT_ARCHIVE="$TOOLS_ROOT/Godot_v4.6-stable_macos.universal.zip"
    GODOT_URL="https://github.com/godotengine/godot-builds/releases/download/4.6-stable/Godot_v4.6-stable_macos.universal.zip"
    GODOT_APP="$TOOLS_ROOT/$GODOT_VERSION/Godot.app"
    DEFAULT_GODOT_BIN="$GODOT_APP/Contents/MacOS/Godot"
    ;;
  Linux)
    GODOT_ARCHIVE="$TOOLS_ROOT/Godot_v4.6-stable_linux.x86_64.zip"
    GODOT_URL="https://github.com/godotengine/godot-builds/releases/download/4.6-stable/Godot_v4.6-stable_linux.x86_64.zip"
    DEFAULT_GODOT_BIN="$TOOLS_ROOT/$GODOT_VERSION/Godot_v4.6-stable_linux.x86_64"
    ;;
  *)
    echo "Unsupported OS for dev.sh. Use tools/dev.ps1 on Windows." >&2
    exit 1
    ;;
esac

GODOT_BIN="${GODOT_BIN:-$DEFAULT_GODOT_BIN}"

step() {
  printf '==> %s\n' "$1"
}

ensure_godot() {
  if [[ -x "$GODOT_BIN" ]]; then
    return
  fi

  mkdir -p "$TOOLS_ROOT/$GODOT_VERSION"

  if [[ ! -f "$GODOT_ARCHIVE" ]]; then
    step "Downloading Godot $GODOT_VERSION"
    if command -v curl >/dev/null 2>&1; then
      curl -L "$GODOT_URL" -o "$GODOT_ARCHIVE"
    else
      python3 - "$GODOT_URL" "$GODOT_ARCHIVE" <<'PY'
import sys, urllib.request
url, out = sys.argv[1], sys.argv[2]
urllib.request.urlretrieve(url, out)
PY
    fi
  fi

  step "Extracting Godot $GODOT_VERSION"
  if command -v unzip >/dev/null 2>&1; then
    unzip -o "$GODOT_ARCHIVE" -d "$TOOLS_ROOT/$GODOT_VERSION" >/dev/null
  else
    python3 - "$GODOT_ARCHIVE" "$TOOLS_ROOT/$GODOT_VERSION" <<'PY'
import sys, zipfile
archive, target = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(archive) as zf:
    zf.extractall(target)
PY
  fi

  if [[ ! -x "$GODOT_BIN" ]]; then
    chmod +x "$GODOT_BIN" 2>/dev/null || true
  fi

  if [[ ! -x "$GODOT_BIN" ]]; then
    echo "Godot executable was not found after extraction: $GODOT_BIN" >&2
    echo "Set GODOT_BIN to an installed Godot executable if needed." >&2
    exit 1
  fi
}

run_godot() {
  ensure_godot
  "$GODOT_BIN" "$@"
}

show_paths() {
  cat <<EOF
RepoRoot=$REPO_ROOT
ToolsRoot=$TOOLS_ROOT
GodotBin=$GODOT_BIN
WeChatBackup=${MINIGAME_WECHAT_BACKUP:-}
PrototypePdf=${MINIGAME_PROTOTYPE_PDF:-}
EOF
}

case "$COMMAND" in
  paths)
    show_paths
    ;;
  ensure-godot)
    ensure_godot
    echo "$GODOT_BIN"
    ;;
  doctor)
    show_paths
    ensure_godot
    step "Godot version"
    "$GODOT_BIN" --version
    step "Git status"
    git -C "$REPO_ROOT" status --short --branch
    ;;
  verify)
    step "Refreshing Godot project metadata"
    run_godot --headless --editor --path "$REPO_ROOT" --quit
    step "Running main scene smoke test"
    run_godot --headless --path "$REPO_ROOT" --quit-after 2
    ;;
  run)
    ensure_godot
    if [[ "$QUIT_AFTER" != "0" ]]; then
      "$GODOT_BIN" --path "$REPO_ROOT" --quit-after "$QUIT_AFTER"
    else
      "$GODOT_BIN" --path "$REPO_ROOT"
    fi
    ;;
  editor)
    ensure_godot
    "$GODOT_BIN" --editor --path "$REPO_ROOT"
    ;;
  *)
    echo "Usage: $0 {doctor|ensure-godot|verify|run|editor|paths} [quit_after_seconds]" >&2
    exit 1
    ;;
esac
