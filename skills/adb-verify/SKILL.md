---
name: adb-verify
description: >
  Use after building an Android APK to visually verify and functionally test the app on a
  connected device or emulator via ADB. Installs the APK, navigates through screens, takes
  screenshots for visual analysis, sends touch/swipe inputs, checks logcat for crashes, and
  runs through a structured test script. Works with both physical devices and emulators.
---

# ADB Verify: Visual & Functional Android App Testing

Automated testing of Android apps via ADB. Installs the APK, drives the UI with touch inputs, takes screenshots for visual verification, and checks for crashes — all without writing Espresso or UI Automator test code.

## When to Use

- After building an Android APK and you want to verify it actually works
- After droid/autopilot completes an Android app build
- When you need to visually verify screens match requirements
- When you want to smoke test an app's critical paths
- User says "test the app", "verify on device", "check if it works", "run it"

## Prerequisites

Before starting, verify the environment:

```bash
# Check ADB is available
adb version

# Check for connected devices
adb devices -l
```

If no device is connected:
1. Check for a running emulator: `adb devices`
2. If none, try starting one: `emulator -avd <avd_name> -no-window &` (list AVDs with `emulator -list-avds`)
3. If no emulators configured, inform the user: "No device or emulator found. Connect a device via USB or start an emulator."

**Do not proceed without a connected device.**

## The Verification Loop

```
For each screen/feature in the test script:
  1. NAVIGATE — send ADB inputs to reach the target screen
  2. WAIT — pause for animations/loading (sleep 1-2s)
  3. CAPTURE — take a screenshot and pull it locally
  4. ANALYZE — examine the screenshot visually for correctness
  5. VERIFY — check UI hierarchy for expected elements
  6. LOG CHECK — scan logcat for crashes or errors
  7. REPORT — log pass/fail with evidence

After all screens tested:
  - Run stability test (monkey runner)
  - Final crash check
  - Generate summary report
```

## ADB Command Reference

### Device Management
```bash
# List connected devices
adb devices -l

# Wait for device to be ready
adb wait-for-device

# Get device screen resolution
adb shell wm size

# Get device density
adb shell wm density
```

### APK Installation
```bash
# Install (replace existing)
adb install -r path/to/app.apk

# Install with grant all permissions
adb install -r -g path/to/app.apk

# Verify installation
adb shell pm list packages | grep <package_name>

# Get APK info before installing
aapt dump badging path/to/app.apk 2>/dev/null | grep -E 'package:|launchable-activity:'
```

### App Lifecycle
```bash
# Launch app (extract package and activity from APK)
adb shell am start -n <package>/<activity>

# Force stop app
adb shell am force-stop <package>

# Clear app data
adb shell pm clear <package>

# Check if app is in foreground
adb shell dumpsys activity activities | grep -E 'mResumedActivity|topResumedActivity'
```

### Screenshots & Screen Capture
```bash
# Take screenshot (save to device, pull locally)
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png ./screenshots/screenshot_<name>.png
adb shell rm /sdcard/screenshot.png

# One-liner with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
adb shell screencap -p /sdcard/screen.png && adb pull /sdcard/screen.png "./screenshots/${TIMESTAMP}_<label>.png" && adb shell rm /sdcard/screen.png
```

### Touch & Gesture Input
```bash
# Tap at coordinates (x, y)
adb shell input tap <x> <y>

# Long press (tap with duration)
adb shell input swipe <x> <y> <x> <y> 1000

# Swipe (x1, y1 → x2, y2, duration_ms)
adb shell input swipe <x1> <y1> <x2> <y2> <duration>

# Swipe up (scroll down) — center of screen
adb shell input swipe 540 1500 540 500 300

# Swipe down (scroll up)
adb shell input swipe 540 500 540 1500 300

# Swipe left
adb shell input swipe 900 1000 100 1000 300

# Swipe right
adb shell input swipe 100 1000 900 1000 300

# Type text
adb shell input text "hello"

# Key events
adb shell input keyevent KEYCODE_BACK
adb shell input keyevent KEYCODE_HOME
adb shell input keyevent KEYCODE_ENTER
adb shell input keyevent KEYCODE_TAB
adb shell input keyevent KEYCODE_VOLUME_UP
```

### UI Hierarchy (for finding tap targets)
```bash
# Dump UI hierarchy to XML
adb shell uiautomator dump /sdcard/ui.xml
adb pull /sdcard/ui.xml ./screenshots/ui_hierarchy.xml
adb shell rm /sdcard/ui.xml

# Parse for clickable elements with bounds
# Each element has: bounds="[left,top][right,bottom]"
# Tap target = center of bounds: x=(left+right)/2, y=(top+bottom)/2
```

### Logcat (Crash & Error Detection)
```bash
# Recent logs (last 200 lines)
adb logcat -d -t 200

# Filter for crashes and errors
adb logcat -d -t 200 | grep -iE '(FATAL|AndroidRuntime|CRASH|Exception|Error)'

# Filter for specific package
adb logcat -d -t 200 | grep <package_name>

# Clear log buffer (before a test run)
adb logcat -c

# Continuous monitoring (run in background)
adb logcat | grep -iE '(FATAL|CRASH|Exception)' &
```

### Monkey Runner (Stability/Stress Test)
```bash
# Send 500 random events to the app
adb shell monkey -p <package> -v --throttle 100 --pct-touch 50 --pct-motion 25 --pct-syskeys 5 --pct-nav 10 --pct-appswitch 5 --pct-anyevent 5 500

# More aggressive: 2000 events
adb shell monkey -p <package> -v --throttle 50 2000

# Check exit code: 0 = survived, non-zero = crash
```

## Coordinate Strategy

Screen coordinates depend on device resolution. Always start by getting the screen size:

```bash
# Get resolution
SIZE=$(adb shell wm size | grep -oE '[0-9]+x[0-9]+')
WIDTH=$(echo $SIZE | cut -dx -f1)
HEIGHT=$(echo $SIZE | cut -dx -f2)
echo "Screen: ${WIDTH}x${HEIGHT}"
```

Then use **relative positions** for common targets:
- **Center of screen:** `$((WIDTH/2))` `$((HEIGHT/2))`
- **Top-center (status bar area):** `$((WIDTH/2))` `$((HEIGHT/10))`
- **Bottom-center (nav bar area):** `$((WIDTH/2))` `$((HEIGHT*9/10))`
- **FAB (bottom-right):** `$((WIDTH*5/6))` `$((HEIGHT*5/6))`
- **Bottom nav items (5 items):** divide width into 5 segments, tap center of each

For precise targets, **always dump and parse the UI hierarchy** first:
```bash
adb shell uiautomator dump /sdcard/ui.xml
adb pull /sdcard/ui.xml ./ui.xml
# Then parse bounds to find exact tap coordinates
```

## Screenshot Analysis

After taking each screenshot, analyze it by reading the image file. Look for:

1. **Layout correctness:** Are elements positioned where expected? Headers, buttons, content areas?
2. **Text readability:** Can you read the text? Is it truncated or overlapping?
3. **Color accuracy:** Do colors match the spec? Are themes applied correctly?
4. **State correctness:** Does the screen show the expected state? (e.g., game over screen after collision, timer showing correct time)
5. **Missing elements:** Is anything missing that should be there? Empty lists, missing icons, blank areas?
6. **Visual regressions:** Does it look broken? Overlapping elements, clipped content, wrong orientation?

**Report for each screenshot:**
```
Screen: <screen name>
Screenshot: <file path>
Status: PASS / FAIL / WARNING
Observations:
  - [what you see]
  - [what matches expectations]
  - [what doesn't match, if any]
```

## Test Script Structure

When testing an app, build a test script based on the app's screens and features. Structure it as:

### Phase 1: Installation & Launch
1. Install APK
2. Verify package installed
3. Launch app
4. Wait for splash screen (if any)
5. Screenshot: splash screen
6. Wait for main screen
7. Screenshot: main/home screen
8. Crash check

### Phase 2: Screen Navigation
For each screen in the app:
1. Navigate to the screen (tap buttons, swipe, etc.)
2. Wait for load
3. Screenshot: screen in default state
4. Crash check
5. Interact with screen elements (fill forms, tap toggles, etc.)
6. Screenshot: screen in modified state
7. Navigate back
8. Crash check

### Phase 3: Critical Path Testing
Test the app's main user flows end-to-end:
1. For a game: start game, play a few rounds, verify scoring, trigger game over
2. For a productivity app: create item, modify it, complete it, verify state changes
3. For any app: test settings changes persist, test navigation between all screens

### Phase 4: Edge Cases
1. Rotate device: `adb shell settings put system accelerometer_rotation 0 && adb shell settings put system user_rotation 1` (landscape), then back to portrait
2. Background/foreground: `adb shell input keyevent KEYCODE_HOME`, wait 3s, relaunch — verify state preserved
3. Force stop and relaunch — verify persistent data survived

### Phase 5: Stability
1. Clear logcat: `adb logcat -c`
2. Run monkey: 500-1000 events
3. Check for crashes in logcat
4. Screenshot: current state after monkey test

### Phase 6: Report
Generate a summary:
```
## ADB Verification Report

**App:** <package name>
**Device:** <device model and Android version>
**APK:** <path to tested APK>
**Date:** <timestamp>

### Results

| Screen/Test | Status | Screenshot | Notes |
|-------------|--------|------------|-------|
| Splash      | PASS   | splash.png | Loaded in ~1.5s |
| Main Menu   | PASS   | menu.png   | All buttons visible |
| Game Play   | PASS   | game.png   | Physics working correctly |
| ...         | ...    | ...        | ... |

### Crash Report
- Crashes found: 0
- ANRs found: 0
- Logcat errors: [list or "none"]

### Monkey Test
- Events sent: 500
- Crashes: 0
- Result: PASS

### Overall: PASS / FAIL
```

## Game-Specific Testing

For game apps (Flappy Bird, Tetris, etc.), add these tests:

### Flappy Bird
1. Launch → screenshot main menu
2. Tap "Play" → screenshot game start (bird at starting position)
3. Rapid taps (5x) → screenshot mid-game (bird should be high)
4. Do nothing for 3s → screenshot (bird should fall, likely game over)
5. Verify game over screen shows score
6. Tap "Retry" → verify game restarts
7. Navigate to Settings → toggle sound → verify toggle state

### Tetris
1. Launch → screenshot main menu
2. Tap "Play" → screenshot game start (piece at top)
3. Swipe left/right → screenshot (piece should move)
4. Swipe down → screenshot (piece should soft drop)
5. Wait for pieces to stack → screenshot mid-game
6. Navigate to Settings → change theme → screenshot
7. Start Sprint mode → verify timer visible

### Pomodoro App
1. Launch → screenshot home screen
2. Create a task: navigate to create screen, input text, save
3. Screenshot task list → verify task appears
4. Start pomodoro linked to task → screenshot timer running
5. Wait 5s → screenshot timer (verify countdown)
6. Navigate to stats → screenshot (verify initial state)
7. Navigate to settings → change work duration → verify

## Integration with Other Skills

**Called after:** autopilot (Phase 4), droid completion, any Android APK build
**Uses:** verification-before-completion (this IS verification evidence)
**Provides:** Visual proof that the app works, crash-free evidence, screenshot artifacts

## Red Flags

**Never:**
- Skip the crash check after navigation (logcat is cheap, crashes are expensive)
- Assume coordinates — always get screen size first, prefer UI hierarchy parsing
- Test without clearing app data first (stale state hides bugs)
- Skip the monkey test (it finds crashes humans miss)
- Claim "app works" without screenshots as evidence

**Always:**
- Create a `screenshots/` directory for all captures
- Name screenshots descriptively: `01_splash.png`, `02_main_menu.png`, etc.
- Check logcat after every major interaction
- Get screen resolution before sending any tap coordinates
- Parse UI hierarchy when you need precise tap targets
- Generate the summary report at the end
