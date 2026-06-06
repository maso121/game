import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../state/game_notifier.dart';
import '../utils/app_theme.dart';

// ─────────────────────────────────────────────
//  BOTTOM BAR — Power-ups & Undo
// ─────────────────────────────────────────────
class BottomBarTools extends ConsumerWidget {
  const BottomBarTools({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);
    final canUndo = gameState.moveHistory.isNotEmpty &&
        gameState.phase == GamePhase.playing;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          _ProgressBar(
            cleared: gameState.clearedPlates,
            total: gameState.plates.length,
          ),
          const SizedBox(height: 12),
          // Tool row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ToolButton(
                icon: Icons.undo_rounded,
                label: 'Undo',
                color: AppColors.primaryAccent,
                isEnabled: canUndo,
                onTap: canUndo ? () => notifier.undoLastMove() : null,
              ),
              _ToolButton(
                icon: Icons.auto_fix_high_rounded,
                label: 'Auto',
                color: AppColors.successGreen,
                isEnabled: true,
                badge: '🎯',
                onTap: () => _showAdRewardDialog(context),
              ),
              _ToolButton(
                icon: Icons.bolt_rounded,
                label: 'Blast',
                color: AppColors.plateRuby,
                isEnabled: true,
                badge: '⚡',
                onTap: () => _showAdRewardDialog(context),
              ),
              _ToolButton(
                icon: Icons.more_time_rounded,
                label: '+Time',
                color: AppColors.plateYellow,
                isEnabled: true,
                badge: '⏱',
                onTap: () => _showAdRewardDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAdRewardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Watch an Ad?', style: AppTextStyles.displayLarge.copyWith(fontSize: 20)),
        content: Text(
          'Watch a short video to unlock this power-up.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No thanks'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_circle_filled_rounded),
            label: const Text('Watch'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int cleared;
  final int total;

  const _ProgressBar({required this.cleared, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? cleared / total : 0.0;
    return Row(
      children: [
        Text(
          'Progress',
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.plateCyan, AppColors.successGreen],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.successGreen.withOpacity(0.4),
                        blurRadius: 6,
                      )
                    ],
                  ),
                ),
              ).animate(key: ValueKey(cleared)).fadeIn(duration: 300.ms),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$cleared/$total',
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isEnabled;
  final String? badge;
  final VoidCallback? onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isEnabled,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.35,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.4), width: 1.5),
                    boxShadow: isEnabled
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: Text(badge!, style: const TextStyle(fontSize: 11)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 11,
                color: isEnabled ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
