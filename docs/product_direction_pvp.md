# 4399 Minigame Product Direction - Local PK MVP

## Evidence Used

- Current repository: Godot 4 project with a single-board card placement puzzle, 6x5 board, hand UI, chain scoring, and `data/card_pool.json`.
- Prototype PDF from Tang Zoutao: live platform wrapper, lobby, streamer identity confirmation, VS intro, dual PK board, action/effect selection, battle recap, heat leaderboard.
- 2026-06-29 meeting note: final core play must be aligned before 2026-07-05; direction is same-screen local PVP, not mobile networking or AI opponent; 10-round heat contest; values should move from 1-6 to 1-4; keep same type + same number adjacent elimination; add streamer-style progress, bullet comments, and compact action windows.
- Bilibili reference video for King of Veggies: same number + same type adjacent cards drop by one layer and score; border placement increases value; basket card clears nearby same-number groups; late game pressure rises as random values increase.
- Related early proposals: platform/content operation, user resonance, AI KPI, and narrative experiments. These should not become the final mechanics, but they can feed the live-broadcast world view and result-report language.
- WeChat PC backup package: file structure was readable, but chat packages were encrypted/binary. No reliable plaintext discussion was extracted from the backup body.

## Final Positioning

The game should be a same-screen streamer PK card puzzle:

Two streamers fight for heat in a short live broadcast. Each player has an independent stage board. Players place talent cards such as singing, dancing, and Rap. Adjacent same talent + same number cards trigger heat, drop numbers, and may chain. Special cards create small disruptions or cleanup moments. After 10 turns, the higher heat wins, unless a player fills their board and loses early.

The target feeling is not pure farming and not pure match-3. It should feel like:

- "I can understand the rule in 20 seconds."
- "Every placement is a small trap or setup."
- "My opponent can see what I am building."
- "The screen reacts like a live PK room, so scoring feels performative."
- "One more round might let me reverse the heat bar."

## What Makes It Fun

1. Simple rule, high readability
   Same type + same number is the only core elimination rule. The player can instantly predict most outcomes.

2. Local PVP creates pressure that the reference game does not have
   King of Veggies is mostly about fighting the random deck and board space. Our version adds social pressure: both players see score, board danger, remaining turns, and possible setups.

3. Heat is a better score fantasy than vegetables
   Heat, bullet comments, PK progress, and streamer personas make every chain feel like a public performance rather than abstract points.

4. Short 10-turn format gives a clear arc
   The game should ramp from setup to comeback to final swing. A short match is easier to test, replay, and show in a booth or classroom.

5. Special cards can become personality
   A small set of disruption cards can create "audience interference" moments: boost opponent cells, lock a grid, force a discard, copy a card, or clean a number. These are more memorable than pure score modifiers.

## Optimization Over King Of Veggies

Reference strengths to keep:

- Drag cards from hand to board.
- Same type + same number adjacency.
- Values drop layer by layer instead of disappearing immediately.
- Border placement changes value and creates spatial planning.
- A basket-like special card gives board control.

Reference pain points to improve:

- Randomness can feel unfair when the deck keeps giving unusable high values.
- Single-player scoring lacks direct drama after the player understands the system.
- Late game can become a slow death when board space is blocked.
- There is little reason to care about "who" is playing.

Our answers:

- Lower value range to 1-4 for the MVP.
- Use 10-turn PK instead of endless survival.
- Use local PVP so pressure comes from the opponent, not only RNG.
- Use limited special cards to create controlled reversals.
- Use live-room UI to turn every score burst into visible heat, audience reaction, and recap stats.

## MVP Rule Set

- Board: each player has one 6-column x 5-row stage board.
- Basic cards: Singing, Dancing, Rap.
- Card values: 1-4.
- Placement: place cards into empty cells only.
- Border bonus: top row or left column adds +1 to a normal card once.
- Elimination: adjacent orthogonal same type + same value cards form a group, drop by 1, and score heat per affected card.
- Removal: cards reaching 0 leave the board.
- Special card v1: keep the current basket/cleanup card as the first special.
- Match length: 10 turns per player for the first playable PVP build.
- Early loss: a player who cannot place because their board is full loses immediately.
- Win condition: after both players finish 10 turns, higher heat wins. Tie can be "PK draw" in the MVP.

## PVP Expansion Candidates

Use only 3-5 special cards in the final demo. Avoid turning the game into a text-heavy card battler.

- Raise Hype: choose one opponent cell, value +1. It can break their setup or push a card out of matching range.
- Mic Drop: remove one value-1 card from your board.
- Trend Copy: copy the type of the last card your opponent played, with a random value 1-4.
- Lag Spike: opponent's next drawn card is hidden until their turn starts.
- Fan Gift: score +2 if the played card triggers at least one chain this turn.

## UI Direction

- First screen should be the playable PK table, not a landing page.
- Layout: P1 board left, P2 board right, shared PK header on top, active player's hand/actions near the bottom or side.
- Top header: P1 heat, P2 heat, round count, active player, PK progress bar.
- Add lightweight bullet comments as reactive feedback after scoring, not as a manual tutorial.
- Result screen: winner, final heat, heat gap, max chain, full-board status, rematch button, leaderboard hook.
- Avoid covering the board with large modals during core placement.

## Development Priorities

1. Local PVP loop
   Two player states, active player switching, 10 turns per player, early full-board loss, final heat comparison.

2. Rule clarity
   Keep all scoring in `scripts/puzzle/game_state.gd`. UI should only display and animate results.

3. Feedback pass
   Heat bar, active player label, turn counter, chain messages, and recap stats.

4. Special card pass
   Add disruption cards only after the base loop feels good.

5. Art pass
   Replace placeholder cards with streamer talent icons and character portraits. Keep icon colors readable first.

## Open Questions

- Is a "turn" one card placement, or one draft/action bundle from 10 shared cards?
- Should players draft from a shared 10-card row, or keep private hands?
- Should special cards target the opponent board directly, or create global live-room events?
- Should full board be an instant loss or a forced stop that compares current heat?
- Do we want streamer names/avatars to be chosen in the prototype flow, or hard-code P1/P2 for the demo?
