# Smoke Test: Tetris Clone (Android APK)

Tests droid persistence across a complex game with precise mechanics (SRS rotation, scoring, wall kicks). Expected runtime: 8-10+ hours.

## The Prompt

```
droid Build a complete Tetris clone as a native Android app in Kotlin with Jetpack Compose. Generate a signed APK.

REQUIREMENTS:

Game mechanics (exact classic Tetris behavior per Tetris Guideline):
- 10-wide, 20-tall visible grid (plus 2 hidden rows above for spawn)
- 7 tetrominoes: I (cyan), O (yellow), T (purple), S (green), Z (red), J (blue), L (orange)
- Random Generator: 7-bag randomizer — shuffle all 7 pieces, deal them in order, reshuffle when bag empties
- Piece spawns centered at top (row 21-22), drops one cell per tick
- Gravity speed by level: Level 1 = 1 cell/second, Level 2 = 1.2/s, ..., Level 10 = 5/s, Level 15 = 10/s, Level 20 = 20/s (use standard NES Tetris speed curve)
- Soft drop: hold down = 20x normal speed, adds 1 point per cell
- Hard drop: instant placement, adds 2 points per cell dropped
- Lock delay: 500ms after piece lands on surface before locking, resets on successful move/rotate (max 15 resets)
- Wall kicks: use Super Rotation System (SRS) — implement all 5 kick tests for each rotation for all pieces including I-piece special cases
- Line clear scoring (per Tetris Guideline):
  - Single: 100 × level
  - Double: 300 × level
  - Triple: 500 × level
  - Tetris (4 lines): 800 × level
  - Back-to-back Tetris bonus: 1.5× multiplier
  - T-spin detection: check 3 of 4 corners occupied after T rotation
  - T-spin Single: 800 × level, T-spin Double: 1200 × level, T-spin Triple: 1600 × level
- Level increases every 10 lines cleared
- Game over: piece cannot spawn without overlapping existing blocks

Controls:
- Left/right swipe or tap left/right screen halves to move piece
- Swipe down for soft drop
- Swipe up for hard drop
- Tap piece or rotate button to rotate clockwise
- Two-finger tap or second rotate button for counter-clockwise rotation
- Hold button (top-left): stores current piece, swaps with held piece (once per drop)
- D-pad overlay option in settings (virtual buttons instead of gesture controls)

Screens and navigation:
- Splash screen with animated falling tetrominoes (3 pieces cascade down and lock)
- Main menu: "Play", "Marathon", "Sprint (40 lines)", "High Scores", "Settings", "How to Play"
- Game screen layout:
  - Center: 10×20 grid with thin gridlines
  - Right panel: Next queue showing next 5 pieces
  - Left panel: Hold piece display, score, level, lines cleared
  - Ghost piece: translucent outline showing where piece will land
  - Pause button top-right corner
- Pause overlay: Resume, Restart, Quit
- Game over screen: final score, level reached, lines cleared, time played, high score comparison, Retry and Menu buttons
- Sprint mode: clear 40 lines as fast as possible, show timer prominently, leaderboard by time
- Marathon mode: standard endless play, leaderboard by score
- High scores: separate tabs for Marathon and Sprint, top 10 each, stored in Room database with date and lines/level
- Settings: toggle ghost piece, toggle grid lines, toggle sound, toggle vibration, choose control scheme (gesture vs d-pad), choose starting level (1-15), theme (classic, modern dark, modern light)
- How to Play: scrollable tutorial with diagrams explaining controls, T-spins, back-to-back, scoring

Visual design:
- Each block is a rounded rectangle with gradient fill (lighter on top-left, darker on bottom-right for 3D effect)
- Draw all block colors programmatically with Canvas
- Line clear animation: flash white 3 times over 500ms, then collapse
- T-spin indicator: "T-SPIN!" text animates in from side when detected
- Back-to-back indicator: "BACK-TO-BACK" text appears above score
- Tetris clear: "TETRIS!" text with brief screen shake (2dp amplitude, 200ms)
- Combo counter: display "COMBO ×N" for consecutive line-clearing drops
- Level-up flash: brief golden border flash on grid
- Three themes:
  - Classic: black background, bright solid block colors
  - Modern Dark: dark gray background, block colors with subtle gradients
  - Modern Light: white background, pastel block colors

Audio (generate programmatically):
- Piece move: short 500Hz tick, 15ms
- Piece rotate: short 700Hz tone, 25ms
- Soft landing (lock): low 300Hz thud, 40ms
- Hard drop: 250Hz impact, 60ms
- Single line clear: ascending scale C-E-G, 50ms each
- Double line clear: C-E-G-C5, 50ms each
- Triple line clear: C-E-G-C5-E5, 40ms each
- Tetris clear: fanfare — C-E-G-C5 as chord, 300ms
- T-spin: distinctive two-note motif, 400Hz-800Hz, 100ms each
- Game over: descending C-A-F-D, 150ms each
- Level up: quick ascending arpeggio

Architecture:
- MVVM + clean architecture with Hilt
- Domain layer: GameEngine (pure Kotlin, no Android dependencies), Board, Piece, RotationSystem (SRS), Scorer, RandomBag
- Data layer: Room database for high scores, DataStore for settings
- Presentation layer: GameViewModel, Compose screens
- GameEngine is a pure state machine: takes Input (move, rotate, drop, hold, tick) → produces new GameState
- GameState: board grid (Array<Array<BlockColor?>>), active piece (type, position, rotation), held piece, next queue, score, level, lines, combo count, back-to-back flag, phase (Playing, Paused, GameOver)
- Game loop: coroutine with configurable tick interval based on level

Testing (comprehensive):
- Unit tests for SRS rotation including all wall kick scenarios (at least 20 test cases covering I-piece wall kicks, T-piece kicks, kicks near walls, kicks near floor, kicks near other blocks)
- Unit tests for 7-bag randomizer (each piece appears exactly once per bag, all 7 present, next bag starts after empty)
- Unit tests for line clear detection (single, double, triple, tetris, with various board configurations)
- Unit tests for T-spin detection (all valid T-spin scenarios: T-spin mini, T-spin single, T-spin double, T-spin triple, and non-T-spin controls)
- Unit tests for scoring (correct points for each clear type, back-to-back multiplier, combo counting, soft/hard drop points, level multiplier)
- Unit tests for lock delay (resets on move, resets on rotate, max 15 resets, locks after 500ms with no input)
- Unit tests for game over detection (piece overlaps on spawn)
- Unit tests for hold piece (swap works, can't hold twice per drop, empty hold at start)
- Unit tests for ghost piece position calculation
- UI tests: tap starts game, swipe moves piece, game over displays after filling board
- Integration test: play a scripted game — place specific pieces to clear a tetris, verify score equals 800

Build configuration:
- Min SDK 24, target SDK 34, compile SDK 34
- Kotlin 2.0+, Compose BOM latest, Hilt
- Debug and release APKs with generated keystore
- ProGuard rules
- Adaptive app icon: T-piece (purple) on dark background
- Run ALL tests, fix ALL failures, build both APKs, verify with aapt dump badging
```

## What to Verify

- [ ] Droid skill activated (check for `.gemini/state/droid.json`)
- [ ] Model did not pause to ask "shall I continue?" between major phases
- [ ] SRS wall kick tests all pass (this is the hardest logic)
- [ ] All unit tests pass
- [ ] Both debug and release APKs generated
- [ ] Total session time logged
