# 4399 Minigame Product Direction - Current PVP Prototype

## Current Baseline

This branch has been synced with `origin/jch`, which currently contains the latest playable direction and the most complete foundation for battle logic and PVP experience.

The project is no longer the early single-board hand-card prototype. The current architecture includes:

- Start screen entry flow.
- Local match layout prototype.
- Card-flow gameplay test.
- LAN connection test.
- PVP match test.
- Android/PC LAN export/test preparation.
- Balance and layout config files.
- Dedicated core board/card state classes.

## Final Positioning

The game is a live-stream themed PVP card puzzle.

Two players compete for heat by drafting cards from a public pool, placing them onto their own boards, triggering same-value/same-type chains, using props, and trying to swing the PK heat bar. The fun should come from readable puzzle tactics plus the pressure of racing another player inside a live broadcast wrapper.

The target feeling:

- Rules are understandable quickly.
- The public pool creates shared pressure and small fights over resources.
- Basket capacity forces short-term planning.
- Board placement creates chain setup and cleanup decisions.
- Heat bar and comeback compensation make the match feel alive.
- Props give controlled reversal moments without turning the game into a heavy text-card battler.

## Current Gameplay Loop

1. Round starts.
2. Public pool refills to 10 cards.
3. Pool is locked briefly with a visual cover/falling-card moment.
4. Claim phase begins.
5. Players claim cards from the public pool into baskets.
6. Claim ends when baskets are full or time expires.
7. Place phase begins.
8. Players drag basket cards onto their own board.
9. Placement triggers chain resolution and heat scoring.
10. When baskets are empty, the next round starts.

The single-player card-flow test scene currently exercises this loop most directly:

- `scenes/card_flow_test.tscn`
- `scripts/ui/card_flow_test_ui.gd`

The network PVP test scene is the current LAN authority path:

- `scenes/pvp_network_test.tscn`
- `scenes/pvp_match_test.tscn`
- `scripts/ui/pvp_network_test_ui.gd`
- `scripts/ui/pvp_match_test_ui.gd`

## Core Rules

- Boards use `UiLayoutConfig.BOARD_COLUMNS` and `UiLayoutConfig.BOARD_ROWS`.
- Public pool size is 10.
- Basket size is 4.
- Normal cards currently include:
  - 游戏
  - 聊天
  - 才艺
- Wildcard cards are supported.
- Border placement bonus: top row or left column increases placed card value by 1.
- Same type + same value orthogonal groups resolve together.
- Wildcards match any type with the same value and disappear after resolving.
- Cards drop one layer when resolved; cards at 0 are removed.
- Heat score comes from affected cards, removed cards, and multi-step chains.

## Balance Surface

Primary file:

- `scripts/config/game_balance_config.gd`

Important parameters:

- `WILD_CARD_WEIGHT`
- `NORMAL_CARD_TYPES`
- `WILD_CARD_DATA`
- `VALUE_PROBABILITY_BY_ROUND`

The current prototype uses round-based value probabilities, gradually increasing access to higher values.

## Props

Current prop candidates:

- `消`: remove one target card.
- `+1`: increase one target card's value by 1 and resolve if possible.
- `-1`: decrease one target card's value by 1 and resolve if possible.

Rules:

- `scripts/core/player_board_state.gd`

UI:

- `scripts/ui/local_prop_view.gd`

## Optimization Over King Of Veggies

Keep:

- Simple adjacency matching.
- Layer-drop resolution.
- Board pressure.
- Special cleanup/reversal tools.

Improve:

- Reduce pure solitaire feeling through shared public pool and PVP.
- Convert score into live-stream heat pressure.
- Add comeback compensation and props to fight random dead states.
- Use timed claim/place phases to create rhythm and urgency.

## Development Priorities

1. Stabilize the `pvp_match_test` authority flow.
2. Connect props into network PVP.
3. Move card/art/balance data into editable config resources or data files where useful.
4. Improve result/recap UI.
5. Add final visual assets for cards, avatars, props, live-room UI, and backgrounds.
6. Tune probability tables and comeback thresholds after playtesting.

## Files To Know

- `project.godot`: starts at `scenes/start_screen.tscn`.
- `docs/local_pvp_ui_notes.md`: current detailed design and implementation notes.
- `docs/android_pc_lan_testing.md`: PC/Android LAN testing/export notes.
- `scripts/core/player_board_state.gd`: board rules.
- `scripts/config/game_balance_config.gd`: balance.
- `scripts/config/ui_layout_config.gd`: layout constants.
- `scripts/ui/card_flow_test_ui.gd`: local gameplay loop test.
- `scripts/ui/pvp_match_test_ui.gd`: network PVP match test.
