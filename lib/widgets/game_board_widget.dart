import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_models.dart';
import '../state/game_notifier.dart';
import '../painters/board_painters.dart';
import '../utils/board_coordinates.dart';
import '../utils/app_theme.dart';
import '../utils/physics_utils.dart';
import 'animated_screw_widget.dart';

// ═══════════════════════════════════════════════════════════════════
//  GAME BOARD WIDGET
//
//  Layer order (bottom → top):
//    1. BoardBackgroundPainter  (wood frame + steel base + grid)
//    2. HolePainter             (empty screw holes)
//    3. Plate layers (z-ordered, locked plates drawn as CustomPaint)
//    4. Falling plates          (_PhysicsFallingPlate — uses physics_utils)
//    5. Screws in holes         (_ScrewInHoleWidget)
//    6. Active screws           (AnimatedScrewWidget — tappable)
//    7. Flying screw overlay    (ScrewFlyWidget — Bézier arc to hole)
//    8. Pause overlay
// ═══════════════════════════════════════════════════════════════════
class GameBoardWidget extends ConsumerStatefulWidget {
  const GameBoardWidget({super.key});

  @override
  ConsumerState<GameBoardWidget> createState() => _GameBoardWidgetState();
}

class _GameBoardWidgetState extends ConsumerState<GameBoardWidget> {
  BoardCoordinates? _coords;

  /// Tracks screws currently flying to a hole.
  /// Key = screwId, Value = target hole position in global coords.
  final Map<String, Offset> _flyingTargets = {};

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final sortedPlates = ref.watch(sortedPlatesProvider);
    final activeScrews = ref.watch(activeScrewsProvider);
    final holeScrews = ref.watch(holesScrewsProvider);
    final hintScrewId = ref.watch(hintScrewIdProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);

      // ── Recompute board coordinates any time size changes ──
      _coords = BoardCoordinates.fromSize(
        screenSize: size,
        columns: gameState.level.gridColumns,
        rows: gameState.level.gridRows,
      );
      final coords = _coords!;

      return SizedBox.expand(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ════════════════════════════════
            //  LAYER 1 — Board background
            // ════════════════════════════════
            RepaintBoundary(
              child: CustomPaint(
                size: size,
                painter: BoardBackgroundPainter(coords: coords),
              ),
            ),

            // ════════════════════════════════
            //  LAYER 2 — Holes
            // ════════════════════════════════
            CustomPaint(
              size: size,
              painter: HolePainter(holes: gameState.holes, coords: coords),
            ),

            // ════════════════════════════════
            //  LAYER 3 & 4 — Plates
            // ════════════════════════════════
            ...sortedPlates.map((plate) {
              if (plate.state == PlateState.cleared) {
                return const SizedBox.shrink();
              }

              if (plate.state == PlateState.free) {
                // Immediately trigger fall — widget handles animation
                return _PhysicsFallingPlate(
                  key: ValueKey('fall_${plate.id}'),
                  plate: plate,
                  coords: coords,
                  canvasSize: size,
                  onFallComplete: () => notifier.onPlateFallComplete(plate.id),
                );
              }

              // Locked or static
              return RepaintBoundary(
                key: ValueKey('plate_${plate.id}'),
                child: CustomPaint(
                  size: size,
                  painter: PlatePainter(
                    plate: plate,
                    coords: coords,
                    isHighlighted: false,
                  ),
                ),
              );
            }),

            // ════════════════════════════════
            //  LAYER 5 — Screws settled in holes
            // ════════════════════════════════
            ...holeScrews.map((screw) {
              final holeCenter =
                  coords.cellCenterGlobal(screw.boardPosition);
              return _ScrewInHoleWidget(
                key: ValueKey('hole_screw_${screw.id}'),
                screw: screw,
                center: holeCenter,
                radius: coords.cellSize * 0.21,
              );
            }),

            // ════════════════════════════════
            //  LAYER 6 — Active (tappable) screws
            // ════════════════════════════════
            if (gameState.phase == GamePhase.playing ||
                gameState.phase == GamePhase.paused)
              ...activeScrews.map((screw) {
                return AnimatedScrewWidget(
                  key: ValueKey('active_${screw.id}'),
                  screw: screw,
                  coords: coords,
                  isHinted: screw.id == hintScrewId,
                  onTap: () {
                    final handled = notifier.onScrewTapped(screw.id);
                    if (!handled) {
                      // Visual shake — nothing to do here; handled in notifier
                    }
                  },
                  onAnimationComplete: () {
                    // Determine target hole for fly animation
                    final freeHole = gameState.nextFreeHole();
                    if (freeHole != null) {
                      final targetCenter =
                          coords.cellCenterGlobal(freeHole.gridPosition);
                      setState(() {
                        _flyingTargets[screw.id] = targetCenter;
                      });
                    }
                    notifier.onUnscrewComplete(screw.id);
                  },
                );
              }),

            // ════════════════════════════════
            //  LAYER 7 — Flying screw arcs
            // ════════════════════════════════
            ..._flyingTargets.entries.map((entry) {
              final screwId = entry.key;
              final targetPos = entry.value;

              // Find the screw model (may already be in unscrewed state)
              final screwModel = gameState.screws.firstWhere(
                (s) => s.id == screwId,
                orElse: () => ScrewModel(
                  id: screwId,
                  boardPosition: Offset.zero,
                  color: AppColors.screwGold,
                ),
              );

              final startPos =
                  coords.cellCenterGlobal(screwModel.boardPosition);

              return ScrewFlyWidget(
                key: ValueKey('fly_$screwId'),
                screw: screwModel,
                startGlobal: startPos,
                endGlobal: targetPos,
                onComplete: () {
                  setState(() => _flyingTargets.remove(screwId));
                },
              );
            }),

            // ════════════════════════════════
            //  LAYER 8 — Pause overlay
            // ════════════════════════════════
            if (gameState.phase == GamePhase.paused)
              const _PauseOverlay(),
          ],
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PHYSICS FALLING PLATE
//
//  Uses [FallProfile] + [PlatePhysicsState] from physics_utils.dart
//  to drive a frame-by-frame simulation via a Ticker. This produces
//  genuinely physical motion: accelerating gravity, angular momentum,
//  air-drag damping on spin, and opacity fade on exit.
// ═══════════════════════════════════════════════════════════════════
class _PhysicsFallingPlate extends StatefulWidget {
  final PlateModel plate;
  final BoardCoordinates coords;
  final Size canvasSize;
  final VoidCallback onFallComplete;

  const _PhysicsFallingPlate({
    super.key,
    required this.plate,
    required this.coords,
    required this.canvasSize,
    required this.onFallComplete,
  });

  @override
  State<_PhysicsFallingPlate> createState() => _PhysicsFallingPlateState();
}

class _PhysicsFallingPlateState extends State<_PhysicsFallingPlate>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  late FallProfile _profile;
  late PlatePhysicsState _phys;
  late int _durationMs;
  int _elapsedMs = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();

    // Normalized x position of the plate's origin on the board
    final normX = widget.plate.originCell.dx / widget.coords.columns;
    _profile = FallProfile.forPlate(normalizedX: normX);
    _phys = PlatePhysicsState.fromProfile(_profile);
    _durationMs = _profile.durationMs;

    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (_done) return;

    final dt = (elapsed.inMilliseconds - _elapsedMs) / 1000.0;
    _elapsedMs = elapsed.inMilliseconds;

    _phys.step(
      dt.clamp(0.0, 0.05), // cap dt to avoid physics explosion on lag
      _profile,
      _elapsedMs.toDouble(),
      _durationMs.toDouble(),
    );

    setState(() {}); // rebuild with new physics values

    if (_elapsedMs >= _durationMs && !_done) {
      _done = true;
      widget.onFallComplete();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(_phys.x, _phys.y),
      child: Transform.rotate(
        angle: _phys.angle,
        // Rotate around the plate's visual center for realism
        origin: _plateCenterOffset(),
        child: Opacity(
          opacity: _phys.opacity.clamp(0.0, 1.0),
          child: CustomPaint(
            size: widget.canvasSize,
            painter: PlatePainter(
              plate: widget.plate,
              coords: widget.coords,
              isHighlighted: false,
            ),
          ),
        ),
      ),
    );
  }

  /// Returns the offset to the plate's visual center from the canvas origin.
  /// Used as the rotation pivot so the plate spins around its own center.
  Offset _plateCenterOffset() {
    if (widget.plate.occupiedCells.isEmpty) return Offset.zero;
    double sumX = 0, sumY = 0;
    for (final cell in widget.plate.occupiedCells) {
      final center = widget.coords.cellCenterGlobal(cell);
      sumX += center.dx;
      sumY += center.dy;
    }
    return Offset(
      sumX / widget.plate.occupiedCells.length,
      sumY / widget.plate.occupiedCells.length,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SCREW IN HOLE WIDGET
//  Displays a screw that has been placed into a hole slot.
//  Plays a spring-settle micro-animation on appearance.
// ═══════════════════════════════════════════════════════════════════
class _ScrewInHoleWidget extends StatefulWidget {
  final ScrewModel screw;
  final Offset center;
  final double radius;

  const _ScrewInHoleWidget({
    super.key,
    required this.screw,
    required this.center,
    required this.radius,
  });

  @override
  State<_ScrewInHoleWidget> createState() => _ScrewInHoleWidgetState();
}

class _ScrewInHoleWidgetState extends State<_ScrewInHoleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();

    _scale = Tween<double>(begin: 1.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: ElasticOutCustom(period: 0.38, amplitude: 1.0),
      ),
    );

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.radius;

    return Positioned(
      left: widget.center.dx - r,
      top: widget.center.dy - r,
      width: r * 2,
      height: r * 2,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Opacity(
          opacity: _fade.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _scale.value,
            child: CustomPaint(
              size: Size(r * 2, r * 2),
              painter: _HoleScrewPainter(
                color: widget.screw.color,
                headType: widget.screw.headType,
                radius: r,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoleScrewPainter extends CustomPainter {
  final Color color;
  final ScrewHeadType headType;
  final double radius;

  const _HoleScrewPainter({
    required this.color,
    required this.headType,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = radius * 0.88;

    // Body
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: [
            Colors.white.withOpacity(0.85),
            color.withOpacity(0.8),
            color,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Border
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Tiny drive slot for realism
    canvas.save();
    canvas.translate(center.dx, center.dy);
    final slotPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..strokeWidth = r * 0.22
      ..strokeCap = StrokeCap.round;

    if (headType == ScrewHeadType.flathead) {
      canvas.drawLine(Offset(-r * 0.55, 0), Offset(r * 0.55, 0), slotPaint);
    } else {
      canvas.drawLine(Offset(0, -r * 0.55), Offset(0, r * 0.55), slotPaint);
      canvas.drawLine(Offset(-r * 0.55, 0), Offset(r * 0.55, 0), slotPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HoleScrewPainter old) => false;
}

// ─────────────────────────────────────────────
//  PAUSE OVERLAY
// ─────────────────────────────────────────────
class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.white.withOpacity(0.70),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pause_circle_filled_rounded,
              size: 76,
              color: AppColors.walnutFrame.withOpacity(0.55),
            ),
            const SizedBox(height: 14),
            Text(
              'PAUSED',
              style: TextStyle(
                fontFamily: 'RajdhaniRegular',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.walnutFrame.withOpacity(0.65),
                letterSpacing: 5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the pause button to resume',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.walnutFrame.withOpacity(0.4),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
