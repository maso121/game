import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../state/game_notifier.dart';
import '../utils/app_theme.dart';

// ─────────────────────────────────────────────
//  TOP BAR HUD
// ─────────────────────────────────────────────
class TopBarHud extends ConsumerWidget {
  const TopBarHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // ── Level Badge ─────────────────────
          _LevelBadge(levelNumber: gameState.level.levelNumber),
          const SizedBox(width: 12),

          // ── Retry Button ────────────────────
          _HudButton(
            icon: Icons.refresh_rounded,
            color: AppColors.primaryAccent,
            onTap: () => _showRetryDialog(context, notifier),
          ),

          const Spacer(),

          // ── Moves Counter ───────────────────
          _MovesDisplay(moves: gameState.moveCount),

          const Spacer(),

          // ── Hint Button ─────────────────────
          _HintButton(
            hintsLeft: gameState.hintsRemaining,
            onTap: () {
              final hintScrew = notifier.useHint();
              if (hintScrew != null) {
                ref.read(hintScrewIdProvider.notifier).state = hintScrew;
                // Clear hint after 3 seconds
                Future.delayed(const Duration(seconds: 3), () {
                  if (ref.read(hintScrewIdProvider) == hintScrew) {
                    ref.read(hintScrewIdProvider.notifier).state = null;
                  }
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'No hints remaining!',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                    ),
                    backgroundColor: AppColors.dangerRed,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),

          // ── Pause Button ────────────────────
          _HudButton(
            icon: gameState.phase == GamePhase.paused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            color: AppColors.walnutFrame,
            onTap: notifier.togglePause,
          ),
        ],
      ),
    );
  }

  void _showRetryDialog(BuildContext context, GameNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Retry Level?', style: AppTextStyles.displayLarge.copyWith(fontSize: 22)),
        content: Text(
          'Your progress will be lost.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              notifier.resetLevel();
              Navigator.pop(ctx);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int levelNumber;
  const _LevelBadge({required this.levelNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.levelBadge, Color(0xFFFF8C42)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.levelBadge.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.layers_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 5),
          Text('LEVEL $levelNumber', style: AppTextStyles.levelLabel),
        ],
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HudButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3), width: 1.2),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _MovesDisplay extends StatelessWidget {
  final int moves;
  const _MovesDisplay({required this.moves});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$moves',
          style: AppTextStyles.movesCounter,
        ).animate(key: ValueKey(moves)).scale(
              begin: const Offset(1.3, 1.3),
              end: const Offset(1, 1),
              duration: 200.ms,
              curve: Curves.elasticOut,
            ),
        Text(
          'MOVES',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 10,
            letterSpacing: 1.5,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}

class _HintButton extends StatelessWidget {
  final int hintsLeft;
  final VoidCallback onTap;

  const _HintButton({required this.hintsLeft, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasHints = hintsLeft > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: hasHints
              ? AppColors.hintGlow.withOpacity(0.15)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasHints
                ? AppColors.hintGlow.withOpacity(0.6)
                : Colors.grey.withOpacity(0.3),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_rounded,
              color: hasHints ? AppColors.hintGlow : Colors.grey,
              size: 18,
            ).animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.05, 1.05),
                  duration: 900.ms,
                ),
            const SizedBox(width: 5),
            Text(
              '$hintsLeft',
              style: AppTextStyles.hintCounter.copyWith(
                color: hasHints ? AppColors.hintGlow : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
