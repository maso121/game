import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_models.dart';
import '../utils/board_coordinates.dart';
import '../utils/app_theme.dart';
import '../utils/physics_utils.dart';

// ═══════════════════════════════════════════════════════════════════
//  ANIMATED SCREW WIDGET  (complete rewrite with physics utils)
//
//  STATE MACHINE:
//    screwed      → idle, tappable, slight idle bob animation
//    unscrewing   → rotation + lift animation plays (420ms rotate → 300ms lift)
//    [callback]   → notifier.onUnscrewComplete() fires
//    unscrewed    → widget removed from active layer, appears in hole
// ═══════════════════════════════════════════════════════════════════
class AnimatedScrewWidget extends ConsumerStatefulWidget {
  final ScrewModel screw;
  final BoardCoordinates coords;
  final bool isHinted;
  final VoidCallback onTap;
  final VoidCallback onAnimationComplete;

  const AnimatedScrewWidget({
    super.key,
    required this.screw,
    required this.coords,
    required this.onTap,
    required this.onAnimationComplete,
    this.isHinted = false,
  });

  @override
  ConsumerState<AnimatedScrewWidget> createState() =>
      _AnimatedScrewWidgetState();
}

class _AnimatedScrewWidgetState extends ConsumerState<AnimatedScrewWidget>
    with TickerProviderStateMixin {
  // ── Animation controllers ─────────────────────────────────────
  late AnimationController _unscrew; // drives rotation + lift
  late AnimationController _idleBob; // subtle idle float
  late AnimationController _hintPulse; // pulsing hint ring
  late AnimationController _tapFeedback; // quick scale pop on tap

  // ── Animations ────────────────────────────────────────────────
  late Animation<double> _rotation;
  late Animation<double> _liftY;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<double> _bobY;
  late Animation<double> _hintScale;
  late Animation<double> _tapScale;

  bool _animationFired = false;

  @override
  void initState() {
    super.initState();
    _buildControllers();
    _buildAnimations();
    _startPassiveAnimations();
  }

  void _buildControllers() {
    _unscrew = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );

    _idleBob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _hintPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _tapFeedback = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  void _buildAnimations() {
    // ── Unscrew: rotation ─────────────────────
    // Uses the physics_utils curve: slow start, fast middle
    _rotation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _unscrew,
        curve: const Interval(0.0, 0.72, curve: Curves.easeIn),
      ),
    );

    // ── Unscrew: vertical lift ────────────────
    _liftY = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _unscrew,
        curve: const Interval(0.0, 1.0, curve: GravityCurve()),
      ),
    );

    // ── Unscrew: scale ────────────────────────
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.18),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 0.0),
        weight: 45,
      ),
    ]).animate(CurvedAnimation(
      parent: _unscrew,
      curve: Curves.linear,
    ));

    // ── Unscrew: opacity ──────────────────────
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _unscrew,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── Idle bob ──────────────────────────────
    _bobY = Tween<double>(begin: -1.8, end: 1.8).animate(
      CurvedAnimation(parent: _idleBob, curve: Curves.easeInOut),
    );

    // ── Hint pulse ────────────────────────────
    _hintScale = Tween<double>(begin: 1.0, end: 1.10).animate(
      CurvedAnimation(parent: _hintPulse, curve: Curves.easeInOut),
    );

    // ── Tap feedback ──────────────────────────
    _tapScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.0), weight: 60),
    ]).animate(
      CurvedAnimation(parent: _tapFeedback, curve: Curves.easeOut),
    );

    // ── Completion listener ───────────────────
    _unscrew.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_animationFired) {
        _animationFired = true;
        widget.onAnimationComplete();
      }
    });
  }

  void _startPassiveAnimations() {
    _idleBob.repeat(reverse: true);
    if (widget.isHinted) _hintPulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(AnimatedScrewWidget old) {
    super.didUpdateWidget(old);

    // Screw just entered unscrewing state → play animation
    if (old.screw.state != ScrewState.unscrewing &&
        widget.screw.state == ScrewState.unscrewing) {
      _animationFired = false;
      _idleBob.stop();
      _unscrew.forward(from: 0.0);
    }

    // Hint toggled on/off
    if (!old.isHinted && widget.isHinted) {
      _hintPulse.repeat(reverse: true);
    } else if (old.isHinted && !widget.isHinted) {
      _hintPulse.stop();
      _hintPulse.reset();
    }
  }

  @override
  void dispose() {
    _unscrew.dispose();
    _idleBob.dispose();
    _hintPulse.dispose();
    _tapFeedback.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.screw.canInteract) return;
    _tapFeedback.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final cellSize = widget.coords.cellSize;
    final center = widget.coords.cellCenterGlobal(widget.screw.boardPosition);
    final hitArea = cellSize * 0.88;

    return AnimatedBuilder(
      animation: Listenable.merge([_unscrew, _idleBob, _hintPulse, _tapFeedback]),
      builder: (context, _) {
        final isUnscrewing = widget.screw.state == ScrewState.unscrewing;

        // ── Compute physics offsets ──────────
        final rotAngle = isUnscrewing
            ? screwRotationAngle(_rotation.value)
            : 0.0;

        final liftOffset = isUnscrewing
            ? screwLiftOffset(_liftY.value, cellSize)
            : _bobY.value;

        final currentScale = isUnscrewing
            ? _scale.value * _tapScale.value
            : _hintScale.value * _tapScale.value;

        final currentOpacity = isUnscrewing ? _opacity.value : 1.0;

        // ── Position the hit area ────────────
        return Positioned(
          left: center.dx - hitArea / 2,
          top: center.dy - hitArea / 2 + liftOffset,
          width: hitArea,
          height: hitArea,
          child: Opacity(
            opacity: currentOpacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: currentScale.clamp(0.0, 2.0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleTap,
                child: CustomPaint(
                  size: Size(hitArea, hitArea),
                  painter: _ScrewFacePainter(
                    screw: widget.screw,
                    rotationAngle: rotAngle,
                    isHinted: widget.isHinted,
                    isUnscrewing: isUnscrewing,
                    hintPulse: _hintPulse.value,
                    cellSize: cellSize,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  SCREW FACE PAINTER
//  Draws one screw head in local widget space.
// ─────────────────────────────────────────────
class _ScrewFacePainter extends CustomPainter {
  final ScrewModel screw;
  final double rotationAngle;
  final bool isHinted;
  final bool isUnscrewing;
  final double hintPulse; // 0..1
  final double cellSize;

  const _ScrewFacePainter({
    required this.screw,
    required this.rotationAngle,
    required this.isHinted,
    required this.isUnscrewing,
    required this.hintPulse,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.36;

    // ── Hint / glow rings (behind screw) ────
    if (isHinted) {
      final ringRadius = r + 8 + hintPulse * 5;
      canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..color = AppColors.hintGlow.withOpacity(0.55 + hintPulse * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8,
      );
      canvas.drawCircle(
        center,
        ringRadius + 5,
        Paint()
          ..color = AppColors.hintGlow.withOpacity(0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    if (isUnscrewing) {
      for (int i = 1; i <= 3; i++) {
        canvas.drawCircle(
          center,
          r + i * 5.0,
          Paint()
            ..color = screw.color.withOpacity(0.16 * (4 - i))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      }
    }

    // ── Rotate for head slots ────────────────
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    // Drop shadow
    canvas.drawCircle(
      const Offset(1.5, 2.5),
      r,
      Paint()
        ..color = Colors.black.withOpacity(isUnscrewing ? 0.08 : 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // ── Metallic body ────────────────────────
    final bodyRect = Rect.fromCircle(center: Offset.zero, radius: r);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.38, -0.38),
          colors: [
            Colors.white.withOpacity(0.95),
            screw.color.withOpacity(0.78),
            screw.color,
            Color.lerp(screw.color, Colors.black, 0.25)!,
          ],
          stops: const [0.0, 0.28, 0.68, 1.0],
        ).createShader(bodyRect),
    );

    // ── Edge rim ─────────────────────────────
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = Color.lerp(screw.color, Colors.white, 0.15)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // ── Inner groove ring ────────────────────
    canvas.drawCircle(
      Offset.zero,
      r * 0.7,
      Paint()
        ..color = Colors.black.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // ── Head drive slots ─────────────────────
    _drawDriveSlots(canvas, r * 0.60);

    // ── Specular highlight ───────────────────
    canvas.drawCircle(
      Offset(-r * 0.24, -r * 0.24),
      r * 0.14,
      Paint()..color = Colors.white.withOpacity(0.78),
    );
    canvas.drawCircle(
      Offset(-r * 0.38, -r * 0.34),
      r * 0.06,
      Paint()..color = Colors.white.withOpacity(0.55),
    );

    canvas.restore();
  }

  void _drawDriveSlots(Canvas canvas, double r) {
    final slotPaint = Paint()
      ..color = Colors.black.withOpacity(0.52)
      ..strokeWidth = r * 0.26
      ..strokeCap = StrokeCap.round;

    switch (screw.headType) {
      case ScrewHeadType.hex:
        // 3 symmetrical lines = hexagonal socket
        for (int i = 0; i < 3; i++) {
          final a = i * math.pi / 3;
          canvas.drawLine(
            Offset(math.cos(a) * r * 0.9, math.sin(a) * r * 0.9),
            Offset(math.cos(a + math.pi) * r * 0.9,
                math.sin(a + math.pi) * r * 0.9),
            slotPaint,
          );
        }
        break;

      case ScrewHeadType.phillips:
        // Cross (+) with 45° wedges
        canvas.drawLine(Offset(0, -r), Offset(0, r), slotPaint);
        canvas.drawLine(Offset(-r, 0), Offset(r, 0), slotPaint);
        final thin = Paint()
          ..color = Colors.black.withOpacity(0.28)
          ..strokeWidth = slotPaint.strokeWidth * 0.45
          ..strokeCap = StrokeCap.round;
        for (int q = 0; q < 4; q++) {
          final a = q * math.pi / 2 + math.pi / 4;
          canvas.drawLine(
            Offset(math.cos(a) * r * 0.42, math.sin(a) * r * 0.42),
            Offset(math.cos(a) * r * 0.85, math.sin(a) * r * 0.85),
            thin,
          );
        }
        break;

      case ScrewHeadType.flathead:
        // Single horizontal slot
        canvas.drawLine(Offset(-r, 0), Offset(r, 0), slotPaint);
        // Subtle depth shadow above slot
        canvas.drawLine(
          Offset(-r * 0.85, -slotPaint.strokeWidth * 0.5),
          Offset(r * 0.85, -slotPaint.strokeWidth * 0.5),
          Paint()
            ..color = Colors.black.withOpacity(0.18)
            ..strokeWidth = slotPaint.strokeWidth * 0.3
            ..strokeCap = StrokeCap.round,
        );
        break;

      case ScrewHeadType.torx:
        // 6-point star
        for (int i = 0; i < 6; i++) {
          final a = i * math.pi / 3 + math.pi / 6;
          canvas.drawLine(
            Offset.zero,
            Offset(math.cos(a) * r, math.sin(a) * r),
            slotPaint,
          );
        }
        // Inner hexagon outline
        final hexPath = Path();
        for (int i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          final pt = Offset(math.cos(a) * r * 0.42, math.sin(a) * r * 0.42);
          if (i == 0) {
            hexPath.moveTo(pt.dx, pt.dy);
          } else {
            hexPath.lineTo(pt.dx, pt.dy);
          }
        }
        hexPath.close();
        canvas.drawPath(
          hexPath,
          Paint()
            ..color = Colors.black.withOpacity(0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(_ScrewFacePainter old) =>
      old.rotationAngle != rotationAngle ||
      old.isHinted != isHinted ||
      old.isUnscrewing != isUnscrewing ||
      old.hintPulse != hintPulse ||
      old.screw != screw;
}

// ═══════════════════════════════════════════════════════════════════
//  SCREW-TO-HOLE FLY WIDGET
//  Shows the screw flying from its plate position to the hole slot
//  using a Bézier arc trajectory (ScrewFlyPath from physics_utils).
// ═══════════════════════════════════════════════════════════════════
class ScrewFlyWidget extends StatefulWidget {
  final ScrewModel screw;
  final Offset startGlobal; // screen coords of the plate screw position
  final Offset endGlobal; // screen coords of the destination hole
  final VoidCallback onComplete;

  const ScrewFlyWidget({
    super.key,
    required this.screw,
    required this.startGlobal,
    required this.endGlobal,
    required this.onComplete,
  });

  @override
  State<ScrewFlyWidget> createState() => _ScrewFlyWidgetState();
}

class _ScrewFlyWidgetState extends State<ScrewFlyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late ScrewFlyPath _path;

  @override
  void initState() {
    super.initState();
    _path = ScrewFlyPath(start: widget.startGlobal, end: widget.endGlobal);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onComplete();
      })
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        final pos = _path.evaluate(t);
        const screwR = 12.0;
        final rot = _path.tangentAngle(t.clamp(0.01, 0.99));

        return Positioned(
          left: pos.dx - screwR,
          top: pos.dy - screwR,
          child: Opacity(
            opacity: (1.0 - math.max(0, t - 0.8) / 0.2).clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: rot,
              child: Container(
                width: screwR * 2,
                height: screwR * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.screw.color,
                  border:
                      Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: widget.screw.color.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
