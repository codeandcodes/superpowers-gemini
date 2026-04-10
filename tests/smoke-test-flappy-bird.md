# Smoke Test: Flappy Bird Clone (Android APK)

Tests droid persistence across a full native Android game build. Expected runtime: 6-8+ hours.

## The Prompt

```
droid Build a complete Flappy Bird clone as a native Android app in Kotlin with Jetpack Compose. Generate a signed APK.

REQUIREMENTS:

Game mechanics (exact Flappy Bird behavior):
- Bird is a circular sprite with rotation based on velocity (nose up when tapping, nose down when falling)
- Gravity pulls bird down at 9.8 units/s², tap applies upward impulse of -6 units/s
- Pipes spawn every 1.5 seconds, move left at 120dp/s
- Pipe gap is 150dp, pipe width is 80dp
- Gap vertical position randomized between 20%-80% of screen height
- Collision detection: bird hitbox is a circle with radius 20dp, pipes are rectangles
- Score increments by 1 when bird center passes pipe center-x
- Game over on collision with pipe or floor/ceiling
- Floor scrolls continuously at same speed as pipes

Screens and navigation:
- Splash screen (1.5s) with app logo and "Flappy Clone" title
- Main menu: "Play", "High Scores", "Settings" buttons, animated bird bobbing up and down
- Game screen: score counter top-center, pause button top-right
- Pause overlay: "Resume", "Restart", "Quit" buttons, semi-transparent background
- Game over screen: current score, best score, medal (bronze >= 10, silver >= 20, gold >= 30, platinum >= 40), "Retry" and "Menu" buttons with share button
- High scores screen: top 10 local scores with date, stored in Room database
- Settings screen: toggle sound on/off, toggle vibration on/off, reset high scores with confirmation dialog

Visual assets (generate all programmatically, no external files):
- Bird: draw with Canvas — yellow circle body, orange triangle beak, white/black circle eye, small wing shape
- Pipes: green rectangles with darker green cap (wider rectangle) at opening end
- Background: gradient sky (light blue to white), draw simple cloud shapes that parallax scroll at 50% pipe speed
- Floor: brown rectangle with green grass line on top, tiled texture pattern drawn with Canvas
- Numbers for score: large white text with black outline stroke

Audio (generate with Android's ToneGenerator or AudioTrack):
- Wing flap: short 800Hz sine wave, 50ms
- Score point: short ascending two-tone, 1000Hz then 1200Hz, 30ms each
- Collision/death: low 200Hz tone, 200ms
- Button press: short 600Hz click, 20ms

Architecture:
- MVVM with Hilt dependency injection
- GameViewModel holds game state (bird position, velocity, pipes list, score, game phase)
- Game loop runs at 60fps using LaunchedEffect + withFrameMillis
- GameState sealed class: Menu, Playing, Paused, GameOver
- PipeData class: x position, gap center y, scored boolean
- Repository pattern for high scores with Room database
- DataStore for settings (sound, vibration preferences)

Testing:
- Unit tests for collision detection (bird vs pipe, bird vs floor, bird vs ceiling — at least 10 test cases including edge cases)
- Unit tests for scoring logic (score increments exactly once per pipe, not on re-crossing)
- Unit tests for gravity and tap physics (position after N frames with/without taps)
- Unit tests for pipe spawning (correct interval, gap within bounds, off-screen cleanup)
- Unit tests for high score repository (insert, query top 10, reset)
- UI tests with Compose testing: tap starts game, tap during game applies impulse, game over shows on collision
- Integration test: simulate a full game — tap at correct intervals to pass 5 pipes, verify score is 5

Build configuration:
- Min SDK 24, target SDK 34, compile SDK 34
- Kotlin 2.0+, Compose BOM latest stable
- Generate a debug APK and a release APK signed with a generated keystore
- Build both with: ./gradlew assembleDebug assembleRelease
- Verify both APKs exist and are valid (aapt dump badging)
- ProGuard rules for release build
- App icon: adaptive icon with yellow bird shape on light blue background, generated programmatically in ic_launcher vectors

Project structure:
- Single module, package: com.example.flappyclone
- ui/ — screens, composables, theme
- game/ — GameViewModel, GameEngine, CollisionDetector, PipeSpawner
- data/ — Room database, HighScoreRepository, SettingsDataStore
- audio/ — SoundManager
- di/ — Hilt modules
- Separate source sets for test and androidTest

Run ALL tests. Fix any failures. Build both APKs. Verify they install with: adb install -r app/build/outputs/apk/debug/app-debug.apk (if device available, otherwise just verify APK validity).
```

## What to Verify

- [ ] Droid skill activated (check for `.gemini/state/droid.json`)
- [ ] Model did not pause to ask "shall I continue?" between major phases
- [ ] All unit tests pass
- [ ] Both debug and release APKs generated
- [ ] Total session time logged
