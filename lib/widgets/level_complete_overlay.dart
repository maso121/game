import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../state/game_notifier.dart';
import '../data/level_data.dart';
import '../utils/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════
//  LEVEL COMPLETE OVERLAY
//
//  Shown when GamePhase == levelComplete.
//  Animates in with star rating, move count vs. par, and action buttons.
//  "Next Level" correctly invalidates the game state before navigating.
// ═══════════════════════════════════════════════════════════════════
class LevelCompleteOverlay extends ConsumerWidget {
  const LevelCompleteOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final stars = gameState.starRating;
    final levelIdx = ref.read(currentLevelIndexProvider);
    final totalLevels = LevelData.allLevels.length;
    final hasNext = levelIdx < totalLevels - 1;

    return Container(
      color: Colors.black.withOpacity(0.52),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.successGreen.withOpacity(0.28),
                  blurRadius: 48,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Celebration emoji ──────────
                const Text('🎉', style: TextStyle(fontSize: 56))
                    .animate()
                    .scale(
                      begin: const Offset(0.2, 0.2),
                      end: const Offset(1, 1),
                      duration: 550.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: 10),

                Text('LEVEL CLEAR!', style: AppTextStyles.displayLarge)
                    .animate()
                    .slideY(begin: 0.25, duration: 380.ms, delay: 150.ms)
                    .fadeIn(duration: 280.ms, delay: 150.ms),

                const SizedBox(height: 22),

                // ── Star rating ────────────────
                _StarRow(stars: stars),

                const SizedBox(height: 20),

                // ── Stats ──────────────────────
                _StatRow(
                  icon: Icons.touch_app_rounded,
                  label: 'Your moves',
                  value: '${gameState.moveCount}',
                  color: AppColors.primaryAccent,
                ),
                const SizedBox(height: 6),
                _StatRow(
                  icon: Icons.flag_rounded,
                  label: 'Par moves',
                  value: '${gameState.level.parMoves}',
                  color: AppColors.successGreen,
                ),
                const SizedBox(height: 6),
                _StatRow(
                  icon: Icons.layers_rounded,
                  label: 'Plates cleared',
                  value: '${gameState.clearedPlates}/${gameState.plates.length}',
                  color: AppColors.plateCyan,
                ),

                const SizedBox(height: 28),

                // ── Action buttons ─────────────
                Row(
                  children: [
                    // Replay
                    Expanded(
                      child: _OutlineBtn(
                        icon: Icons.refresh_rounded,
                        label: 'Replay',
                        onTap: () {
                          ref.read(gameStateProvider.notifier).resetLevel();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Next / Home
                    Expanded(
                      flex: 2,
                      child: _FilledBtn(
                        icon: hasNext
                            ? Icons.arrow_forward_rounded
                            : Icons.home_rounded,
                        label: hasNext ? 'Next Level' : 'Home',
                        color: AppColors.successGreen,
                        onTap: () => hasNext
                            ? _goNextLevel(context, ref, levelIdx)
                            : Navigator.of(context)
                                .popUntil((r) => r.isFirst),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 280.ms);
  }

  /// Advances to the next level by:
  ///   1. Writing the new index to the StateProvider
  ///   2. Invalidating gameStateProvider so its notifier is recreated
  ///      with the new level (avoids setState-during-build)
  void _goNextLevel(BuildContext context, WidgetRef ref, int currentIdx) {
    final nextIdx = currentIdx + 1;
    ref.read(currentLevelIndexProvider.notifier).state = nextIdx;
    // Schedule invalidation after the current frame completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(gameStateProvider);
    });
  }
}

// ─────────────────────────────────────────────
//  STAR ROW
// ─────────────────────────────────────────────
class _StarRow extends StatelessWidget {
  final int stars; // 1–3

  const _StarRow({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final filled = i < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: filled ? AppColors.hintGlow : Colors.grey[300],
            size: 46,
          )
              .animate(delay: Duration(milliseconds: 350 + i * 130))
              .scale(
                begin: const Offset(0.15, 0.15),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
                duration: 480.ms,
              )
              .rotate(begin: -0.25, end: 0, duration: 380.ms),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
//  STAT ROW
// ─────────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.movesCounter.copyWith(
            fontSize: 20,
            color: AppColors.walnutFrame,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  BUTTONS
// ─────────────────────────────────────────────
class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.walnutFrame.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.walnutFrame),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.walnutFrame,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilledBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FilledBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
