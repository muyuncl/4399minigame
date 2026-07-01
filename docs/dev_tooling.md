# Development Tooling

This repo includes a small PowerShell helper so setup and verification stay boring.

## One-Time Local Context

Private team files should stay outside git. Store them as user environment variables:

```powershell
[Environment]::SetEnvironmentVariable("MINIGAME_WECHAT_BACKUP", "E:\...\Backup\wxid_xxx", "User")
[Environment]::SetEnvironmentVariable("MINIGAME_PROTOTYPE_PDF", "E:\...\原型图(1).pdf", "User")
```

Current Codex setup already configured these variables for the local machine.

## Commands

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

The helper uses the official Godot Windows build:

- Godot version: 4.6 stable
- Source: `https://github.com/godotengine/godot-builds/releases/download/4.6-stable/Godot_v4.6-stable_win64.exe.zip`
- Default local install directory: `..\tmp\godot` beside this repo

The install directory is intentionally outside the repo so the executable is not committed.

## Agent Notes

- Use `AGENTS.md` first for project direction.
- Use `docs/product_direction_pvp.md` for product reasoning.
- Use `docs/rules_and_collaboration.md` for the current MVP rule surface.
- Use `.\tools\dev.ps1 verify` before handing back gameplay code changes.
