# Codex Handoff - 2026-07-01

This is a compact handoff package for continuing the project from another machine, especially a MacBook.

It is not a literal full transcript of hidden tool calls or system instructions. It preserves the project decisions, user preferences, repo state, commands, and continuation prompts that matter for development.

## User And Collaboration Preferences

- User: 储天一.
- Git author email for this repo: `elinacca@outlook.com`.
- Preferred workflow: comfortable, proactive setup. Codex may autonomously add useful tooling, commands, scripts, MCP/software integrations, and docs when they clearly help game development.
- Sensitive data rule: WeChat chat records are local sensitive context. Use them for design understanding, but do not paste private chat excerpts into public repo files or public responses.
- If image generation/editing is requested, use the `imagegen` Codex skill by default.
- If working on code, prefer implementing and verifying rather than only proposing.

## Current Repo

- GitHub: `https://github.com/muyuncl/4399minigame`
- Local Windows repo path: `G:\MiniGame\4399minigame`
- Active personal branch: `chutianyi`
- Latest gameplay baseline synced from: `origin/jch`
- Main branch should stay stable. Personal work should happen on `chutianyi`, then PR to `main`.
- A safety branch was created before syncing: `backup/chutianyi-before-jch-sync`.

## Current Project State

The project has been synced with the `jch` branch, which currently contains the latest playable battle logic and PVP experience.

The old early prototype files are no longer the main path:

- `scripts/puzzle/game_state.gd` was removed.
- `scripts/ui/main.gd` was removed.
- `data/card_pool.json` was removed.

Current entry point:

- `project.godot`
- `scenes/start_screen.tscn`
- `scripts/ui/start_screen.gd`

Current main test scenes:

- `scenes/local_match.tscn`
- `scenes/card_flow_test.tscn`
- `scenes/pvp_network_test.tscn`
- `scenes/pvp_match_test.tscn`
- `scenes/pvp_lan_network.tscn`

Current core code:

- `scripts/core/player_board_state.gd`
- `scripts/core/pvp_card_data.gd`
- `scripts/config/game_balance_config.gd`
- `scripts/config/ui_layout_config.gd`
- `scripts/ui/card_flow_test_ui.gd`
- `scripts/ui/pvp_match_test_ui.gd`
- `scripts/ui/pvp_network_test_ui.gd`

## Current Gameplay Summary

- Public pool has 10 cards.
- Players claim cards into baskets.
- Basket size is 4.
- Players place basket cards onto their board.
- Same type + same value orthogonal groups resolve.
- Wildcards match any type with same value and disappear after resolving.
- Border placement bonus: top row or left column increases value by 1.
- Resolves score heat and removed-card bonuses.
- Heat bar represents score pressure.
- Comeback compensation can grant props.
- Props currently include remove, +1, and -1.
- LAN PVP uses Host authority: Host validates operations, resolves rules, and broadcasts snapshots.

## Important Docs

- `AGENTS.md`
- `docs/product_direction_pvp.md`
- `docs/rules_and_collaboration.md`
- `docs/local_pvp_ui_notes.md`
- `docs/android_pc_lan_testing.md`
- `docs/dev_tooling.md`

## Windows Tooling

From repo root:

```powershell
.\tools\dev.ps1 doctor
.\tools\dev.ps1 verify
.\tools\dev.ps1 run
.\tools\dev.ps1 editor
```

Windows helper uses Godot 4.6 stable portable under the repo-adjacent temp tools directory:

```text
..\tmp\godot
```

## Mac Setup

Clone and switch branch:

```bash
git clone https://github.com/muyuncl/4399minigame.git
cd 4399minigame
git switch chutianyi
```

Run helper:

```bash
chmod +x tools/dev.sh
./tools/dev.sh doctor
./tools/dev.sh verify
./tools/dev.sh editor
```

The helper can download Godot 4.6 stable for macOS into `../tmp/godot`.

If Godot is already installed elsewhere, set:

```bash
export GODOT_BIN="/path/to/Godot.app/Contents/MacOS/Godot"
```

Optional private local context on Mac:

```bash
export MINIGAME_WECHAT_BACKUP="/path/to/wechat/backup"
export MINIGAME_PROTOTYPE_PDF="/path/to/prototype.pdf"
```

Do not commit private local paths.

## Cross-Platform Safety Notes

Mac and Windows development are compatible for this Godot project as long as both use Godot 4.6 stable and all changes go through Git. The final `.exe` can be exported on Windows even if some gameplay code was written on Mac.

Watch out:

- Do not commit `.godot/`; it is ignored and machine-local.
- Do not commit `.DS_Store`.
- Avoid case-only filename changes because Windows is usually case-insensitive.
- Avoid hard-coded absolute paths like `/Users/...` or `G:\...` inside committed resources.
- If Godot rewrites scenes on either OS, inspect `git diff` before committing.

## Suggested New Codex Prompt

Paste this when starting a new Codex thread:

```text
继续 4399minigame 项目。仓库是 https://github.com/muyuncl/4399minigame，当前分支 chutianyi，最新玩法已从 jch 同步。
请先阅读 AGENTS.md、docs/codex_handoff_2026-07-01.md、docs/local_pvp_ui_notes.md、docs/rules_and_collaboration.md、docs/product_direction_pvp.md、docs/dev_tooling.md。
我的目标是继续完善战斗逻辑/PVP体验。请从 scripts/core/player_board_state.gd、scripts/config/game_balance_config.gd、scripts/ui/card_flow_test_ui.gd、scripts/ui/pvp_match_test_ui.gd 入手，先确认当前状态，再给出最小可玩增量并实现。提交前运行对应平台的 verify 脚本。
```

## Next Development Targets

1. Stabilize PVP match test authority and snapshot flow.
2. Connect props into the network match.
3. Improve result/recap UI.
4. Tune heat bar, comeback thresholds, and card probability.
5. Replace placeholder UI/card/avatar art.
