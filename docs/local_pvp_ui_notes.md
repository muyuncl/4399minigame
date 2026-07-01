# Local PVP UI Notes

This is the v0.1 static UI scaffold for the local two-player demo.

## Editing layout in Godot

Open `scenes/local_match.tscn`.

The editable 1920x1080 canvas is `LocalMatch/DesignRoot`. Most visible UI parts are real scene nodes under it, so they can be selected, moved, and resized in the Godot 2D editor.

Common nodes:

- `DesignRoot/TopBar`: top score bar.
- `DesignRoot/TopBar/RoundBadge`: center round label.
- `DesignRoot/PlayerInfo/P1Name`, `P2Name`: player name labels.
- `DesignRoot/PlayerInfo/P1AvatarHead`, `P2AvatarHead`: avatar head placeholders.
- `DesignRoot/PlayerInfo/P1PropSlots`, `P2PropSlots`: prop slot groups.
- `DesignRoot/LowerArea/P1Area`, `P2Area`: board-side frame panels.
- `DesignRoot/LowerArea/P1Board`, `P2Board`: board controls.
- `DesignRoot/LowerArea/P1Basket`, `P2Basket`: basket card groups.
- `DesignRoot/LowerArea/PublicPool`: public pool frame.
- `DesignRoot/LowerArea/PublicPool/Cards/Card01` through `Card10`: public pool card placeholders.

To move a component:

1. Select the node in the Scene tree.
2. In the 2D view, drag the node to a new position.
3. If the node is hard to click, select it from the Scene tree instead of the canvas.

To resize a component:

1. Select the node.
2. Drag the rectangle handles in the 2D view, or edit `Layout > Transform > Size` in the Inspector.
3. For `Control` nodes, keep anchors at the top-left preset while we are using the 1920x1080 prototype layout.

Runtime scaling:

- `DesignRoot` is authored at 1920x1080.
- `local_match_ui.gd` scales `DesignRoot` at runtime if the window is not exactly 1920x1080.
- Do not move or resize `DesignRoot` unless you intentionally change the whole design canvas.

Board note:

- `P1Board` and `P2Board` generate their grid at runtime based on the node size.
- Resize the board node itself; the cells will fit that size when the scene runs.

Card note:

- Basket cards and public pool cards are individual `LocalCardView` nodes in the scene.
- Move or resize those card nodes directly if you want to tune spacing.

## Art folders

- `assets/ui/`: common UI frames, bars, panels, buttons.
- `assets/cards/`: card art, card frames, card backgrounds.
- `assets/avatars/`: player portrait and streamer stand-in art.
- `assets/icons/`: prop slot icons, phase icons, small status icons.
- `assets/backgrounds/`: start screen and match screen backgrounds.

## Art insertion workflow

1. Put source images into the matching `assets/` folder.
2. Return to Godot and wait for the Import dock to finish importing the files.
3. For scene-level art, open `scenes/local_match.tscn` or the relevant test scene and add/select a `TextureRect`.
4. In the Inspector, set `TextureRect > Texture` to the imported PNG/WebP.
5. Use `Expand Mode = Ignore Size` and `Stretch Mode = Keep Aspect Centered` for avatars/icons, or `Scale`/`Tile` style settings for background panels as needed.

Recommended replacements:

- Background image: add a `TextureRect` above `Background` under `DesignRoot`, then assign an image from `assets/backgrounds/`.
- Avatar art: replace or hide `P1AvatarHead/P1AvatarBody` and `P2AvatarHead/P2AvatarBody`, then add `TextureRect` nodes using `assets/avatars/`.
- Prop icons: add `TextureRect` children under each prop slot, using files from `assets/icons/`.
- UI frames/buttons: use `StyleBoxTexture` or `TextureRect` nodes with files from `assets/ui/`.
- Card art: set `PvpCardData.art_path` to a resource path such as `res://assets/cards/chat_01.png`.

## Layout tuning in code

Most position tuning should now happen in `scenes/local_match.tscn`, not in code.

Keep `scripts/config/ui_layout_config.gd` for shared defaults such as colors, design resolution, row counts, and fallback card sizes.

## Current scene flow

- `project.godot` starts at `scenes/start_screen.tscn`.
- The start button opens `scenes/local_match.tscn`.
- `scripts/ui/local_match_ui.gd` styles the existing scene nodes and fills placeholder card data.

## Art replacement plan

For card art, `PvpCardData` already has `art_path`. `LocalCardView` checks that path and displays the texture when the file exists.

For larger UI art, add `TextureRect` or `StyleBoxTexture` nodes in the relevant view script and point them at files under `assets/`.

Current card test data is generated in `scripts/ui/card_flow_test_ui.gd` and `scripts/ui/local_match_ui.gd`. Later we should move card definitions into a data file, so art paths, colors, labels, and probabilities can be edited without touching UI scripts.

## Test flow scene

`scenes/card_flow_test.tscn` is the isolated single-player gameplay test scene.

It uses the same overall layout language as the local PVP main view: left player board and basket, center public pool, right-side opponent placeholders, top PK bar, round label, and timer placeholder. Only the left player side has gameplay logic for now.

The first playable prototype was backed up as `C:/Users/NewAdmin/Desktop/MG/MinigameV1` before adding the prop system.

Current test loop:

1. Round start: public pool refills to 10 cards. New cards fall in from the public-pool entrance line while a translucent lock cover pulls down inside the pool frame.
2. The public pool stays locked for 2 seconds.
3. The lock cover pulls upward, then claim phase begins.
4. Claim phase: click cards in the public pool for up to 15 seconds.
5. If the basket reaches 4 cards, claim phase ends early.
6. If claim time expires, the system randomly fills the basket from remaining public pool cards.
7. Place phase: drag basket cards onto the left board for up to 30 seconds.
8. Each placement resolves matching, score, removal, chain animation, and heat bar.
9. If place time expires, remaining basket cards are auto-placed into the first available empty cells.
10. When basket is empty, the round ends and the public pool refills back to 10 cards.

Current phase durations live in `scripts/ui/card_flow_test_ui.gd`:

- `ROUND_START_DURATION := 2.0`
- `ROUND_DROP_DURATION := 1.0`
- `ROUND_UNLOCK_DURATION := 1.0`
- `CLAIM_DURATION := 15.0`
- `PLACE_DURATION := 30.0`

## Heat Bar

The top PK heat bar is implemented in `scripts/ui/card_flow_test_ui.gd`.

Current behavior:

- The bar starts balanced at the center.
- P1 uses the left red fill and P2 uses the right blue fill.
- The center divider moves toward the losing side as the score gap changes.
- `HEAT_FULL_SWING_SCORE := 200.0` means a 200-point lead pushes the divider from the center to the far edge. A 20-point lead moves it 10 percent of that center-to-edge distance.
- The current placeholder visual layers are `_heat_left_fill`, `_heat_right_fill`, and `_heat_center_marker`. Replace those nodes or their materials/textures later to swap in final charging effects.

Comeback compensation:

- `COMEBACK_TRIGGER_RATIO := 0.3` means compensation triggers when a side is pushed 30 percent from center toward its own side.
- With the current `HEAT_FULL_SWING_SCORE`, that equals a 60-point deficit.
- Each side can trigger this compensation once per match in the current prototype.
- The lagging side receives one comeback prop. For P1, it prefers props not selected at the start of the match.
- The current feedback is a top-center notice plus a brief prop-slot flash.

The public pool uses a fixed 2-column, 5-row slot layout. When a card is claimed, only cards above it in the same column fall down, leaving empty slots at the top. Round start refills those empty slots from the same top entrance.

The public pool animation positions are also in `scripts/ui/card_flow_test_ui.gd`:

- `POOL_CARD_SPAWN_Y`: where new cards start before falling into public-pool slots.
- `POOL_COVER_POSITION`: final lock-cover position over the pool.
- `POOL_COVER_OFFSCREEN_POSITION`: where the cover starts and exits.

## Balance parameters

Card refresh parameters live in `scripts/config/game_balance_config.gd`.

Useful values:

- `WILD_CARD_WEIGHT`: wildcard refresh ratio. Current value is `0.1`, meaning 10 percent wildcard cards.
- `NORMAL_CARD_TYPES`: normal card type list, including label, short label, and color.
- `WILD_CARD_DATA`: wildcard label, short label, and color.
- `VALUE_PROBABILITY_BY_ROUND`: card value probability table by round range.

The current value probability table follows the prototype document:

- Rounds 1-5: values 1-8 use `[0.2, 0.25, 0.25, 0.2, 0.1, 0, 0, 0]`.
- Rounds 6-10: `[0.2, 0.2, 0.25, 0.15, 0.1, 0.1, 0, 0]`.
- Rounds 11-15: `[0.15, 0.15, 0.15, 0.2, 0.15, 0.1, 0.1, 0]`.
- Rounds 16-20: `[0.1, 0.1, 0.15, 0.15, 0.1, 0.1, 0.1, 0.1]`.
- Rounds 21-25: `[0.1, 0.1, 0.1, 0.1, 0.15, 0.15, 0.15, 0.15]`.

Wildcard matching is implemented in `scripts/core/player_board_state.gd`: a wildcard card matches any card type with the same value. A wildcard resolves only once and disappears immediately after resolving. If a wildcard is placed without matching neighbors, it removes only itself.

## Props

The test scene now opens with a prop selection dialog. Choose exactly 2 props before the first round starts. The selected props appear in the left player's three prop slots.

Current props:

- `消`: remove one target card.
- `+1`: increase one target card's value by 1, then resolve matching from that card if possible.
- `-1`: decrease one target card's value by 1, then resolve matching from that card if possible. If the card reaches 0, it is removed.

Each prop can be used once. Drag a prop onto an existing board card at any phase to use it, including round start, claim, and placement. Placeholder text is used until final prop icons are available.

Prop rules are implemented in `scripts/core/player_board_state.gd` through `apply_prop`. Prop UI is implemented with `scripts/ui/local_prop_view.gd`.

## PVP Network Test

`scenes/pvp_network_test.tscn` is the first LAN PVP connection test scene.

Start screen entry:

- `PVP测试入口`

Current test features:

- Create room with `ENetMultiplayerPeer.create_server`.
- Join room with `ENetMultiplayerPeer.create_client`.
- Default local test address is `127.0.0.1`.
- Default port is `7777`.
- Send a reliable RPC test message to verify that both windows/devices are synchronized.
- Enter `scenes/pvp_match_test.tscn` from both connected windows with `进入对战测试`.

Recommended LAN architecture:

- One device runs as Host.
- The other device runs as Client.
- Host owns the authoritative match state.
- Client sends operation requests such as claim card, place card, and use prop.
- Host validates, resolves rules, then broadcasts state snapshots and resolve events.

Drag synchronization plan:

- Drag start, drag movement, and drag cancel can be sent as lightweight visual-only messages.
- The final drop operation should still be a reliable request validated by the Host.
- Drag movement should use throttling and unreliable/unordered style delivery later, because old cursor positions are not important once a newer one arrives.
- Final operations must use reliable delivery.

Current PVP match test:

- Host controls P1. Client controls P2.
- Host owns public pool, both baskets, both boards, scores, round, and phase.
- Client sends claim/place requests to Host.
- Host validates operations, resolves rules, and broadcasts full match snapshots.
- Round start now refills the public pool and locks it for 4 seconds before claim phase.
- Public pool cards are not refilled during claim phase. Empty slots remain until the next round start.
- PVP public-pool cards and lock cover are clipped inside the public-pool container, so their entrance animation does not cover the upper PK/streamer area.
- PVP public-pool animations use a host-generated `pool_animation_id`, so repeated countdown state syncs do not replay the same falling-card animation.
- Claim phase ends when both baskets are full.
- Place phase ends when both baskets are empty, then a new claim round starts.
- Basket card dragging sends a lightweight remote drag ghost so the other side can see drag movement.

Current PVP match limitations:

- Props are not connected to the network match yet.
- Round-start lock uses a synchronized state and simple cover; the full single-player falling card/cover animation still needs to be migrated.
- Chain animations currently update through state snapshots; event-by-event resolve playback can be migrated after the network authority path is stable.

Local double-instance testing:

1. Run one game window and open `PVP测试入口`.
2. Click `创建房间`.
3. Run a second game window.
4. Open `PVP测试入口`.
5. Keep address as `127.0.0.1`, port `7777`, then click `加入房间`.
6. Click `发送同步测试消息` in either window. Both windows should show the same received message.

Two-device LAN testing:

1. Connect both devices to the same Wi-Fi/router.
2. On the Host device, click `创建房间`.
3. Find the Host device's local IP, such as `192.168.1.23`.
4. On the Client device, enter that IP and port `7777`, then click `加入房间`.
5. If connection fails on Windows, allow Godot or the exported game through Windows Firewall on private networks.
