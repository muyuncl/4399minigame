# Development Tooling

This repo includes small Windows and macOS/Linux helpers so setup and verification stay boring.

## One-Time Local Context

Private team files should stay outside git. Store them as user environment variables:

```powershell
[Environment]::SetEnvironmentVariable("MINIGAME_WECHAT_BACKUP", "E:\...\Backup\wxid_xxx", "User")
[Environment]::SetEnvironmentVariable("MINIGAME_PROTOTYPE_PDF", "E:\...\原型图(1).pdf", "User")
```

Current Codex setup already configured these variables for the local machine.

## Windows Commands

From repo root:

```powershell
.\tools\dev.ps1 doctor
```

Shows repo/tool paths, ensures Godot 4.6 stable exists, prints Godot version, and shows git status if `git` is on PATH.

```powershell
.\tools\dev.ps1 verify
```

Runs Godot headless editor import plus a short main-scene smoke test.

```powershell
.\tools\dev.ps1 run
```

Runs the game with the bundled local Godot executable.

```powershell
.\tools\dev.ps1 editor
```

Opens the project in the Godot editor.

```powershell
.\tools\dev.ps1 paths
```

Prints resolved local paths, including optional private context environment variables.

## Installed Tooling

The Windows helper uses the official Godot Windows build:

- Godot version: 4.6 stable
- Source: `https://github.com/godotengine/godot-builds/releases/download/4.6-stable/Godot_v4.6-stable_win64.exe.zip`
- Default local install directory: `..\tmp\godot` beside this repo

The install directory is intentionally outside the repo so the executable is not committed.

## macOS/Linux Commands

From repo root:

```bash
chmod +x tools/dev.sh
./tools/dev.sh doctor
./tools/dev.sh verify
./tools/dev.sh run
./tools/dev.sh editor
./tools/dev.sh paths
```

The macOS/Linux helper downloads the official Godot 4.6 stable build into `../tmp/godot` by default.

If Godot is already installed, you can override the executable:

```bash
export GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
```

## Cross-Platform Notes

- Use Godot 4.6 stable on both Windows and macOS.
- Keep private local paths in environment variables, not committed project files.
- Do not commit `.godot/`, `.DS_Store`, or machine-local export/build output.
- Avoid case-only filename changes because Windows is usually case-insensitive.
- Inspect `git diff` after opening scenes in either OS.

## Agent Notes

- Use `AGENTS.md` first for project direction.
- Use `docs/product_direction_pvp.md` for product reasoning.
- Use `docs/rules_and_collaboration.md` for the current MVP rule surface.
- Use `.\tools\dev.ps1 verify` on Windows before handing back gameplay code changes.
- Use `./tools/dev.sh verify` on macOS/Linux before handing back gameplay code changes.
