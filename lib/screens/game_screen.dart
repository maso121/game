import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/game_notifier.dart';
import '../widgets/top_bar_hud.dart';
import '../widgets/bottom_bar_tools.dart';
import '../widgets/game_board_widget.dart';
import '../widgets/level_complete_overlay.dart';
import '../utils/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════
//  GAME SCREEN
//
//  Layout (top → bottom):
//    ┌─────────────────────────────────┐
//    │  TopBarHud                      │  fixed height ~58px
//    ├─────────────────────────────────┤
//    │  GameBoardWidget (Expanded)     │  flex: 1, all remaining space
//    ├─────────────────────────────────┤
//    │  BottomBarTools                 │  fixed height ~110px
//    └─────────────────────────────────┘
//
//  When phase == levelComplete, LevelCompleteOverlay covers everything.
// ═══════════════════════════════════════════════════════════════════
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Ensure portrait lock is maintained when returning to this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Release orientation lock when leaving game
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  /// Auto-pause when app goes to background
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.inactive) {
      final phase = ref.read(gameStateProvider).phase;
      if (phase == GamePhase.playing) {
        ref.read(gameStateProvider.notifier).togglePause();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch only the phase to avoid rebuilding the whole tree on every state tick
    final phase = ref.watch(
      gameStateProvider.select((s) => s.phase),
    );
    final isComplete = phase == GamePhase.levelComplete;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      // No AppBar — custom HUD instead
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main Column ─────────────────────
            Column(
              children: [
                // 1. HUD bar
                const TopBarHud(),

                // 2. Puzzle canvas (fills all remaining vertical space)
                const Expanded(
                  child: GameBoardWidget(),
                ),

                // 3. Tool / power-up bar
                const BottomBarTools(),
              ],
            ),

            // ── Level Complete Overlay ──────────
            // Shown on top of everything when puzzle is solved
            if (isComplete)
              const Positioned.fill(
                child: LevelCompleteOverlay(),
              ),
          ],
        ),
      ),
    );
  }
}
