# AGENTS.md

## Project Direction

This project is a Godot 4 mini game prototype for a live-stream themed PVP card puzzle.

Current direction after syncing from `jch`:

- Main branch for personal development: `chutianyi`.
- Latest gameplay baseline: `origin/jch`, merged into `chutianyi`.
- Project entry scene: `scenes/start_screen.tscn`.
- The start screen provides local UI/demo entries and PVP LAN test entries.
- The playable loop now centers on a public pool, player baskets, player boards, timed claim/place phases, heat bar, props, wildcard cards, and LAN PVP test flow.
- Preserve the live platform PK fantasy: heat score, streamer personas, bullet comments/feedback, recap, and leaderboard direction.

Primary current docs:

- `docs/local_pvp_ui_notes.md`
- `docs/android_pc_lan_testing.md`
- `docs/rules_and_collaboration.md`
- `docs/product_direction_pvp.md`
- `docs/dev_tooling.md`

## Local Private Context

Do not hard-code private WeChat or user file paths into committed files.

When current team discussion is needed, read local paths from environment variables:

- `MINIGAME_WECHAT_BACKUP`
- `MINIGAME_PROTOTYPE_PDF`

Treat WeChat content as local sensitive context. Summarize design-relevant conclusions; do not paste large private chat excerpts into repo files or public responses.

## Development Commands

Use the project helper on Windows:

```powershell
.\tools\dev.ps1 doctor
.\tools\dev.ps1 verify
.\tools\dev.ps1 run
.\tools\dev.ps1 editor
```

On macOS/Linux use:

```bash
./tools/dev.sh doctor
./tools/dev.sh verify
./tools/dev.sh run
./tools/dev.sh editor
```

The helpers download Godot 4.6 stable to a local temp tools directory when needed.

## Engineering Rules

- Current gameplay rules live mainly in `scripts/core/player_board_state.gd`.
- Balance and card generation live in `scripts/config/game_balance_config.gd`.
- Shared layout constants live in `scripts/config/ui_layout_config.gd`.
- PVP card data lives in `scripts/core/pvp_card_data.gd`.
- Local/test UI flows live under `scripts/ui/`, especially `card_flow_test_ui.gd`, `pvp_match_test_ui.gd`, and `local_match_ui.gd`.
- Prefer small, playable increments over broad rewrites.
- Verify with Godot headless after script changes:

```powershell
.\tools\dev.ps1 verify
```

On macOS/Linux:

```bash
./tools/dev.sh verify
```

## Current Near-Term Roadmap

1. Keep `chutianyi` synced to the latest playable gameplay branch before starting new work.
2. Stabilize the PVP match test flow and LAN authority model.
3. Connect props cleanly into the network match.
4. Improve result/recap UI and streamer PK feedback.
5. Tune `GameBalanceConfig` probabilities, prop pacing, and comeback compensation.
