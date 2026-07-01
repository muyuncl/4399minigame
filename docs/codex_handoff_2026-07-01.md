# Codex Handoff - 2026-07-01

This file is a compact handoff package for continuing the project from another machine, especially a MacBook.

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
- Main branch should stay stable. Personal work should happen on `chutianyi`, then PR to `main`.
- Latest known checkpoint commit after setup: `5289ea5 Build local PVP demo foundation`.

## Project Direction

The game is a Godot 4 mini game prototype:

- Same-screen local PVP.
- Live-stream PK wrapper.
- Card placement + adjacent same type/same number elimination.
- Heat score, streamer personas, bullet comments, battle recap, leaderboard.
- Inspired by King of Veggies, but optimized toward local PVP drama and lower random frustration.

Current MVP:

- Board: each player has one 6-column x 5-row stage board.
- Card types: Singing, Dancing, Rap.
- Values: 1-4.
- Each player takes up to 10 actions.
- Place one hand card into an empty cell.
- Top row or left column adds +1 to a normal card.
- Orthogonally adjacent same type + same number groups drop by 1 layer and score heat.
- Cards reaching 0 disappear.
- Basket/cleanup card remains the first special card.
- If a player's board fills and they cannot place, they lose early.
- After 10 actions each, higher heat wins.

Important docs:

- `AGENTS.md`
- `docs/product_direction_pvp.md`
- `docs/rules_and_collaboration.md`
- `docs/dev_tooling.md`

## Evidence And Design Inputs Used

- GitHub repo: `muyuncl/4399minigame`.
- Reference video: Bilibili `BV13P4y1y7rW`, King of Veggies gameplay explanation.
- Reference game page: `https://pinchazumos.itch.io/king-of-veggies`.
- Tang Zoutao prototype PDF: live platform lobby, streamer identity, VS intro, dual PK board, action/effect selection, recap, heat leaderboard.
- Meeting note image from 2026-06-29: final direction is same-screen local PVP; no online/mobile/AI opponent priority; values should be reduced to 1-4; keep same type + same number elimination; add live-room UI elements.
- WeChat backup path on Windows was configured as a local environment variable, but raw chat packages looked encrypted/binary during first pass.

## Current Implementation State

Implemented on `chutianyi`:

- `scripts/ui/main.gd` is a same-screen local PVP controller.
- Two `GameState` instances are used, one per player.
- Active player alternates.
- Each player has 10 actions.
- Early full-board loss and final heat comparison exist.
- Header shows score/round/active player/comment feedback.
- Existing drag/drop and chain animation are preserved.
- `data/card_pool.json` uses Singing/Dancing/Rap and values 1-4.
- `scripts/puzzle/game_state.gd` default fallback also uses Rap and max value 4.
- `tools/dev.ps1` exists for Windows Godot setup/verify/run/editor.
- `tools/dev.sh` exists for macOS/Linux Godot setup/verify/run/editor.

## Windows Tooling

From repo root:

```powershell
.\tools\dev.ps1 doctor
.\tools\dev.ps1 verify
.\tools\dev.ps1 run
.\tools\dev.ps1 editor
```

Windows currently uses Godot 4.6 stable portable under the repo-adjacent temp tools directory:

```text
..\tmp\godot
```

On the original Windows desktop, a convenience shortcut was also created for opening this project in the editor:

```text
Godot 4.6 - 4399minigame Editor.lnk
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

Mac development should not break Windows by itself.

Safe:

- Editing `.gd`, `.tscn`, `.tres`, `.json`, `.md`.
- Committing Godot scene/script changes.
- Using the same Godot version: 4.6 stable.
- Final Windows build/exporting to `.exe` from Windows.

Watch out:

- Do not commit `.godot/`; it is ignored and machine-local.
- Do not commit OS junk like `.DS_Store`.
- Avoid case-only filename changes, because Windows file systems are usually case-insensitive.
- Avoid hard-coded absolute paths like `/Users/...` or `G:\...` inside committed resources.
- Keep asset filenames stable and ASCII/simple when possible.
- If Mac Godot rewrites scene metadata, inspect `git diff` before committing.

Recommended sync habit:

```bash
git status
git pull --rebase
git add .
git commit -m "Describe current progress"
git push
```

On Windows, pull before continuing:

```powershell
git switch chutianyi
git pull --rebase
.\tools\dev.ps1 verify
```

## Suggested New Mac Codex Prompt

Paste this when starting a new Mac Codex thread:

```text
继续 4399minigame 项目。仓库是 https://github.com/muyuncl/4399minigame，当前分支 chutianyi。
请先阅读 AGENTS.md、docs/codex_handoff_2026-07-01.md、docs/product_direction_pvp.md、docs/rules_and_collaboration.md、docs/dev_tooling.md。
我的目标是继续实现战斗逻辑。请从 scripts/puzzle/game_state.gd 和 scripts/ui/main.gd 入手，先确认当前状态，再给出最小可玩增量并实现。提交前运行 ./tools/dev.sh verify。
```

## Next Development Targets

1. Battle logic pass:
   - Define whether "turn" means one card placement or a 10-card draft/action bundle.
   - Add per-turn action state cleanly.
   - Track max chain, last played card, early loss reason, and recap stats.

2. Result screen:
   - Match Tang Zoutao prototype: winner, final heat, heat gap, max chain, rounds, full-board status, rematch.

3. Special cards:
   - Keep to 3-5 total.
   - Start with controlled cleanup/interference, not a text-heavy card battler.

4. Feedback:
   - Heat bar and bullet-comment reactions.
   - Active player clarity.
   - Better invalid-placement messages.

5. Playtest:
   - Tune value range, hand size, refill timing, and special card probability.

## Current Answer To Mac/Windows Concern

Mac and Windows development are compatible for this Godot project as long as both use Godot 4.6 stable and all changes go through Git. The final `.exe` can be exported on Windows even if some gameplay code was written on Mac.
