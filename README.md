# 🔩 Screw Puzzle — Flutter Game

A production-ready, physics-driven screw puzzle mobile game built with **Flutter + Riverpod**.

---

## Project Structure

```
lib/
├── main.dart                     # App entry point, ProviderScope, orientation lock
│
├── models/
│   └── game_models.dart          # ScrewModel, PlateModel, HoleModel, LevelModel, GameStateModel
│
├── data/
│   └── level_data.dart           # Pre-built levels (LevelData.allLevels)
│
├── state/
│   └── game_notifier.dart        # GameNotifier (StateNotifier) + all Riverpod providers
│
├── utils/
│   ├── app_theme.dart            # AppColors, AppTextStyles, AppTheme
│   ├── board_coordinates.dart    # Grid ↔ pixel coordinate mapper
│   └── physics_utils.dart        # FallProfile, PlatePhysicsState, ScrewFlyPath,
│                                 #   spring/shake math, custom Curves
│
├── painters/
│   └── board_painters.dart       # BoardBackgroundPainter, HolePainter,
│                                 #   PlatePainter, ScrewPainter (CustomPainter)
│
├── widgets/
│   ├── animated_screw_widget.dart  # AnimatedScrewWidget + ScrewFlyWidget
│   ├── game_board_widget.dart      # GameBoardWidget (central puzzle canvas)
│   ├── top_bar_hud.dart            # Level badge, retry, hint, pause
│   ├── bottom_bar_tools.dart       # Undo, power-ups, progress bar
│   └── level_complete_overlay.dart # Star rating, stats, next level button
│
└── screens/
    ├── home_screen.dart            # Level select grid
    └── game_screen.dart            # Main game screen (assembles all layers)
```

---

## Core Architecture

### State Flow (Riverpod)

```
currentLevelIndexProvider (StateProvider<int>)
        │
        ▼
currentLevelProvider (Provider<LevelModel>)
        │
        ▼
gameStateProvider (StateNotifierProvider<GameNotifier, GameStateModel>)
        │
        ├── sortedPlatesProvider  (plates sorted by z-layer)
        ├── activeScrewsProvider  (screwed + unscrewing screws)
        ├── holesScrewsProvider   (screws placed in holes)
        ├── isLevelCompleteProvider
        └── hintScrewIdProvider
```

### Screw Tap → Plate Fall Pipeline

```
User taps screw
      │
      ▼
AnimatedScrewWidget.onTap()
      │
      ▼
GameNotifier.onScrewTapped(screwId)
  → sets screw.state = ScrewState.unscrewing
      │
      ▼ (animation plays: rotate × 3.5 turns + lift + fly)
      │
AnimatedScrewWidget.onAnimationComplete()
  → calculates target hole center
  → launches ScrewFlyWidget (Bézier arc)
  → calls GameNotifier.onUnscrewComplete(screwId)
      │
      ▼
GameNotifier.onUnscrewComplete()
  → screw placed in free hole  (ScrewState.unscrewed)
  → plate.activeScrewIds -= screwId
  → if plate.activeScrewIds.isEmpty → PlateState.free
      │
      ▼ (state update triggers rebuild)
      │
GameBoardWidget detects PlateState.free
  → mounts _PhysicsFallingPlate widget
  → FallProfile computed (gravity, swing direction, angular velocity)
  → PlatePhysicsState ticked each frame via Ticker
  → opacity fades at 60% progress
  → onFallComplete() fired at durationMs
      │
      ▼
GameNotifier.onPlateFallComplete()
  → plate.state = PlateState.cleared
  → _checkWinCondition()
  → if all plates cleared → GamePhase.levelComplete
      │
      ▼
LevelCompleteOverlay shown
```

---

## Physics System (`physics_utils.dart`)

| Class/Function | Purpose |
|---|---|
| `FallProfile` | Immutable gravity + swing parameters per plate |
| `PlatePhysicsState` | Mutable frame state (pos, velocity, angle, opacity) |
| `ScrewFlyPath` | Quadratic Bézier arc from plate → hole |
| `SpringValue` | Damped spring for screw settle micro-animation |
| `ShakeAnimation` | Decaying sinusoidal shake for wrong-move feedback |
| `screwRotationAngle(t)` | S-curve mapped to rotation radians |
| `screwLiftOffset(t, cellSize)` | Vertical lift during unscrew |
| `GravityCurve` | Accelerating drop curve |
| `ElasticOutCustom` | Configurable elastic overshoot |
| `AnticipationCurve` | Pull-back before motion |

---

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run on device / emulator
flutter run

# Build release APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

## Adding New Levels

Edit `lib/data/level_data.dart` and add a new static method following the
`level1()` pattern. Add it to the `allLevels` getter list.

Each level defines:
- `PlateModel` list (shape, color, occupied cells, initial screw IDs, z-layer)  
- `ScrewModel` list (position, color, head type, plate IDs it pins)
- `HoleModel` list (empty slots for placed screws)
- `parMoves` (target for 3-star rating)

## Dependencies

```yaml
flame: ^1.18.0          # Game loop (optional — currently using Flutter Ticker)
flutter_riverpod: ^2.5.1 # State management
google_fonts: ^6.2.1     # Rajdhani, Share Tech Mono, Nunito
flutter_animate: ^4.5.0  # UI micro-animations
audioplayers: ^6.0.0     # SFX (wired up, assets to be added)
equatable: ^2.0.5        # Value equality for models
collection: ^1.18.0      # firstWhereOrNull
```
"# game" 
