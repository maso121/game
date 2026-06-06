import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../state/game_notifier.dart';
import '../data/level_data.dart';
import '../utils/app_theme.dart';
import '../models/game_models.dart';
import 'game_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  HOME SCREEN — Level Select
// ═══════════════════════════════════════════════════════════════════
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = LevelData.allLevels;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo row
                    Row(
                      children: [
                        _LogoIcon(),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SCREW',
                              style: AppTextStyles.displayLarge.copyWith(
                                fontSize: 28,
                                height: 1.05,
                              ),
                            ),
                            Text(
                              'PUZZLE',
                              style: AppTextStyles.displayLarge.copyWith(
                                fontSize: 28,
                                height: 1.05,
                                color: AppColors.levelBadge,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                        .animate()
                        .slideX(begin: -0.18, duration: 500.ms, curve: Curves.easeOut)
                        .fadeIn(duration: 400.ms),

                    const SizedBox(height: 8),
                    Text(
                      'Unscrew the plates to solve each puzzle!',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.grey[600]),
                    ).animate().fadeIn(delay: 180.ms, duration: 400.ms),

                    const SizedBox(height: 28),

                    // Section label
                    Text(
                      'SELECT LEVEL',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 11,
                        letterSpacing: 2.5,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ── Level Grid ─────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final level = levels[index];
                    return _LevelCard(
                      level: level,
                      colorIndex: index,
                      onTap: () => _launchLevel(context, ref, index),
                    )
                        .animate(delay: Duration(milliseconds: 60 * index))
                        .fadeIn(duration: 380.ms)
                        .slideY(begin: 0.18, duration: 380.ms, curve: Curves.easeOut);
                  },
                  childCount: levels.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.08,
                ),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }

  /// Navigate to GameScreen for [levelIndex].
  /// Sets the level index provider, then invalidates the game state
  /// so the notifier is recreated with the fresh level.
  void _launchLevel(BuildContext context, WidgetRef ref, int levelIndex) {
    ref.read(currentLevelIndexProvider.notifier).state = levelIndex;
    // Invalidate *after* setting index so the new notifier picks up the right level
    ref.invalidate(gameStateProvider);

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const GameScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.04),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  LOGO ICON
// ─────────────────────────────────────────────
class _LogoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.screwGold, Color(0xFFD4880E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.screwGold.withOpacity(0.45),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(Icons.settings, color: Colors.white, size: 28),
    );
  }
}

// ─────────────────────────────────────────────
//  LEVEL CARD
// ─────────────────────────────────────────────
class _LevelCard extends StatefulWidget {
  final LevelModel level;
  final int colorIndex;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.colorIndex,
    required this.onTap,
  });

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent =
        AppColors.plateColors[widget.colorIndex % AppColors.plateColors.length];

    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        widget.onTap();
      },
      onTapCancel: () => _press.reverse(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.28), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.16),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon circle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withOpacity(0.25), width: 1.5),
                ),
                child: Icon(Icons.settings, color: accent, size: 26),
              ),

              const SizedBox(height: 10),

              Text(
                'Level ${widget.level.levelNumber}',
                style: AppTextStyles.displayLarge.copyWith(
                  fontSize: 17,
                  color: AppColors.walnutFrame,
                ),
              ),

              const SizedBox(height: 4),

              // Screw count badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, color: accent, size: 13),
                  const SizedBox(width: 2),
                  Text(
                    '${widget.level.screws.length} screws',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Star row (3 stars = unlocked/best)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Icon(
                    Icons.star_rounded,
                    // TODO: read saved star rating from SharedPreferences
                    color: AppColors.hintGlow,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
