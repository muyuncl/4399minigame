# AGENTS.md

## Project Direction

This project is a Godot 4 mini game prototype for a same-screen local PVP live-stream PK card puzzle.

Core direction:

- Keep the main mode as local same-screen PVP.
- Do not prioritize online multiplayer, mobile adaptation, or AI opponent work unless the user explicitly changes direction.
- The fantasy is a live platform PK room: heat score, streamer personas, bullet comments, recap, and leaderboard.
- The mechanical base is inspired by King of Veggies: place cards, adjacent same type + same number groups drop by one layer, score heat, and remove at 0.
- Current MVP values: Singing, Dancing, Rap; value range 1-4; each player has a 6-column x 5-row board; each player gets 10 actions.

Primary product spec:

- `docs/product_direction_pvp.md`
- `docs/rules_and_collaboration.md`

## Local Private Context

Do not hard-code private WeChat or user file paths into committed files.

When current team discussion is needed, read local paths from environment variables:

- `MINIGAME_WECHAT_BACKUP`
- `MINIGAME_PROTOTYPE_PDF`

Treat WeChat content as local sensitive context. Summarize design-relevant conclusions; do not paste large private chat excerpts into repo files or public responses.

## Development Commands

Use the project helper:

```powershell
.\tools\dev.ps1 doctor
.\tools\dev.ps1 verify
.\tools\dev.ps1 run
.\tools\dev.ps1 editor
```

The helper downloads Godot 4.6 stable to a local temp tools directory when needed.

## Engineering Rules

- Keep game rules in `scripts/puzzle/game_state.gd`.
- Keep card data in `scripts/puzzle/card_data.gd` and `data/card_pool.json`.
- UI should display, animate, and route player actions; avoid hiding gameplay rules in UI nodes.
- Prefer small, playable increments over broad rewrites.
- Verify with Godot headless after script changes:

```powershell
.\tools\dev.ps1 verify
```

## Current Near-Term Roadmap

1. Polish local PVP flow: active player clarity, turn count, final recap.
2. Add a proper result screen matching Tang Zoutao's prototype.
3. Add 3-5 special cards only after the base loop feels good.
4. Add streamer portraits, card icons, and bullet-comment feedback.
5. Playtest for RNG frustration and adjust deck weights/value ranges.
