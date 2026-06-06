import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../utils/app_theme.dart';
import '../utils/board_coordinates.dart';

// ═════════════════════════════════════════════
//  BOARD BACKGROUND PAINTER
//  Draws the wooden frame + steel base + grid
// ═════════════════════════════════════════════
class BoardBackgroundPainter extends CustomPainter {
  final BoardCoordinates coords;

  const BoardBackgroundPainter({required this.coords});

  @override
  void paint(Canvas canvas, Size size) {
    _drawWoodFrame(canvas);
    _drawSteelBase(canvas);
    _drawGrid(canvas);
  }

  void _drawWoodFrame(Canvas canvas) {
    const frameThickness = 12.0;
    final frameRect = Rect.fromLTWH(
      coords.boardOrigin.dx - frameThickness,
      coords.boardOrigin.dy - frameThickness,
      coords.boardWidth + frameThickness * 2,
      coords.boardHeight + frameThickness * 2,
    );

    // Outer shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect.inflate(4), const Radius.circular(14)),
      shadowPaint,
    );

    // Wood gradient simulation
    final woodPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.walnutFrameLight,
          AppColors.walnutFrame,
          AppColors.walnutFrameLight.withOpacity(0.8),
          AppColors.walnutFrame,
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(frameRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(12)),
      woodPaint,
    );

    // Wood grain lines
    final grainPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 0.8;
    for (int i = 0; i < 8; i++) {
      final y = frameRect.top + i * (frameRect.height / 8);
      canvas.drawLine(
        Offset(frameRect.left, y),
        Offset(frameRect.right, y + 4),
        grainPaint,
      );
    }
  }

  void _drawSteelBase(Canvas canvas) {
    final baseRect = Rect.fromLTWH(
      coords.boardOrigin.dx,
      coords.boardOrigin.dy,
      coords.boardWidth,
      coords.boardHeight,
    );

    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFE8F0F8),
          AppColors.steelBase,
          const Color(0xFFD8E4EE),
        ],
      ).createShader(baseRect);

    canvas.drawRect(baseRect, basePaint);

    // Subtle steel texture
    final texPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 0.4;
    for (int i = 0; i < coords.rows * 3; i++) {
      final y = baseRect.top + i * (coords.cellSize / 3);
      canvas.drawLine(
        Offset(baseRect.left, y),
        Offset(baseRect.right, y),
        texPaint,
      );
    }
  }

  void _drawGrid(Canvas canvas) {
    final gridPaint = Paint()
      ..color = AppColors.gridLine.withOpacity(0.5)
      ..strokeWidth = 0.6;

    final origin = coords.boardOrigin;

    // Vertical lines
    for (int col = 0; col <= coords.columns; col++) {
      final x = origin.dx + col * coords.cellSize;
      canvas.drawLine(
        Offset(x, origin.dy),
        Offset(x, origin.dy + coords.boardHeight),
        gridPaint,
      );
    }
    // Horizontal lines
    for (int row = 0; row <= coords.rows; row++) {
      final y = origin.dy + row * coords.cellSize;
      canvas.drawLine(
        Offset(origin.dx, y),
        Offset(origin.dx + coords.boardWidth, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(BoardBackgroundPainter old) =>
      old.coords.boardOrigin != coords.boardOrigin ||
      old.coords.cellSize != coords.cellSize;
}

// ═════════════════════════════════════════════
//  HOLE PAINTER
//  Draws the empty screw holes on the base plate
// ═════════════════════════════════════════════
class HolePainter extends CustomPainter {
  final List<HoleModel> holes;
  final BoardCoordinates coords;

  const HolePainter({required this.holes, required this.coords});

  @override
  void paint(Canvas canvas, Size size) {
    for (final hole in holes) {
      final center = coords.cellCenterGlobal(hole.gridPosition);
      final radius = coords.cellSize * 0.22;

      // Shadow
      canvas.drawCircle(
        center + const Offset(1, 2),
        radius,
        Paint()..color = Colors.black.withOpacity(0.25),
      );

      // Hole fill
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = hole.isOccupied
              ? AppColors.holeFilled
              : AppColors.holeEmpty.withOpacity(0.6),
      );

      // Inner ring
      canvas.drawCircle(
        center,
        radius * 0.65,
        Paint()
          ..color = Colors.black.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      // Specular highlight
      canvas.drawCircle(
        center - Offset(radius * 0.3, radius * 0.3),
        radius * 0.18,
        Paint()..color = Colors.white.withOpacity(0.5),
      );
    }
  }

  @override
  bool shouldRepaint(HolePainter old) => old.holes != holes;
}

// ═════════════════════════════════════════════
//  PLATE PAINTER
//  Draws a single plate with candy-glass effect
// ═════════════════════════════════════════════
class PlatePainter extends CustomPainter {
  final PlateModel plate;
  final BoardCoordinates coords;
  final bool isHighlighted;

  const PlatePainter({
    required this.plate,
    required this.coords,
    this.isHighlighted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (plate.state == PlateState.cleared) return;

    final path = _buildPlatePath();
    final color = plate.color;

    // Drop shadow
    final shadowPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path.shift(const Offset(3, 5)), shadowPaint);

    // Glass body
    final bodyPaint = Paint()
      ..color = color.withOpacity(plate.isLocked ? 0.72 : 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bodyPaint);

    // Gloss overlay (top-left highlight)
    final glossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.38),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(path.getBounds());
    canvas.drawPath(path, glossPaint);

    // Border
    final borderPaint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHighlighted ? 2.5 : 1.5;
    canvas.drawPath(path, borderPaint);

    // Hint highlight ring
    if (isHighlighted) {
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(path.shift(const Offset(-1, -1)), highlightPaint);
    }

    // Locked icon (small lock badge)
    if (plate.isLocked) {
      _drawLockedBadge(canvas, path.getBounds(), color);
    }
  }

  Path _buildPlatePath() {
    final path = Path();
    final cellSize = coords.cellSize;
    final origin = coords.boardOrigin;
    const radius = 5.0;

    // Build merged rectangle path from occupied cells
    for (final cell in plate.occupiedCells) {
      final rect = Rect.fromLTWH(
        origin.dx + cell.dx * cellSize + 1,
        origin.dy + cell.dy * cellSize + 1,
        cellSize - 2,
        cellSize - 2,
      );
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(radius));
      path.addRRect(rr);
    }

    return path;
  }

  void _drawLockedBadge(Canvas canvas, Rect bounds, Color color) {
    final center = bounds.center;
    final r = coords.cellSize * 0.14;

    // Badge circle
    canvas.drawCircle(
      center,
      r + 3,
      Paint()..color = Colors.white.withOpacity(0.85),
    );

    // Lock icon simplified as arc + rect
    final lockPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // Shackle arc
    canvas.drawArc(
      Rect.fromCenter(center: center - Offset(0, r * 0.5), width: r * 1.4, height: r * 1.3),
      math.pi,
      math.pi,
      false,
      lockPaint,
    );
    // Lock body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center + Offset(0, r * 0.4), width: r * 1.6, height: r * 1.2),
        const Radius.circular(2),
      ),
      Paint()
        ..color = color.withOpacity(0.85)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(PlatePainter old) =>
      old.plate != plate || old.isHighlighted != isHighlighted;
}

// ═════════════════════════════════════════════
//  SCREW PAINTER
//  Draws a single screw head with metallic sheen
// ═════════════════════════════════════════════
class ScrewPainter extends CustomPainter {
  final ScrewModel screw;
  final BoardCoordinates coords;
  final double rotationAngle; // for animation
  final bool isHinted;
  final bool isGlowing;

  const ScrewPainter({
    required this.screw,
    required this.coords,
    this.rotationAngle = 0.0,
    this.isHinted = false,
    this.isGlowing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = coords.cellCenterGlobal(screw.boardPosition);
    final radius = coords.cellSize * 0.28;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    _drawScrewBody(canvas, radius);
    _drawScrewHead(canvas, radius);

    if (isGlowing) _drawGlowRing(canvas, radius);
    if (isHinted) _drawHintRing(canvas, radius);

    canvas.restore();
  }

  void _drawScrewBody(Canvas canvas, double radius) {
    final color = screw.color;

    // Drop shadow
    canvas.drawCircle(
      const Offset(1.5, 2.5),
      radius,
      Paint()..color = Colors.black.withOpacity(0.3),
    );

    // Outer ring (metallic rim)
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [
            Colors.white.withOpacity(0.9),
            color.withOpacity(0.8),
            color,
            color.withOpacity(0.6),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
    );

    // Border ring
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = color.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawScrewHead(Canvas canvas, double radius) {
    final innerR = radius * 0.62;
    final grooveColor = Colors.black.withOpacity(0.55);
    final grPaint = Paint()
      ..color = grooveColor
      ..strokeWidth = radius * 0.22
      ..strokeCap = StrokeCap.round;

    switch (screw.headType) {
      case ScrewHeadType.hex:
        _drawHexSlots(canvas, innerR, grPaint);
        break;
      case ScrewHeadType.phillips:
        _drawPhillipsCross(canvas, innerR, grPaint);
        break;
      case ScrewHeadType.flathead:
        canvas.drawLine(
          Offset(-innerR, 0),
          Offset(innerR, 0),
          grPaint,
        );
        break;
      case ScrewHeadType.torx:
        _drawTorxStar(canvas, innerR, grPaint);
        break;
    }

    // Center dot specular highlight
    canvas.drawCircle(
      Offset(-radius * 0.2, -radius * 0.2),
      radius * 0.12,
      Paint()..color = Colors.white.withOpacity(0.7),
    );
  }

  void _drawHexSlots(Canvas canvas, double r, Paint paint) {
    for (int i = 0; i < 3; i++) {
      final angle = i * math.pi / 3;
      canvas.drawLine(
        Offset(math.cos(angle) * r, math.sin(angle) * r),
        Offset(math.cos(angle + math.pi) * r, math.sin(angle + math.pi) * r),
        paint,
      );
    }
  }

  void _drawPhillipsCross(Canvas canvas, double r, Paint paint) {
    canvas.drawLine(Offset(0, -r), Offset(0, r), paint);
    canvas.drawLine(Offset(-r, 0), Offset(r, 0), paint);
    // Diagonal notches
    final sp = paint..strokeWidth = paint.strokeWidth * 0.5;
    canvas.drawLine(Offset(-r * 0.5, -r * 0.5), Offset(-r * 0.5, -r * 0.2), sp);
    canvas.drawLine(Offset(r * 0.5, -r * 0.5), Offset(r * 0.5, -r * 0.2), sp);
    canvas.drawLine(Offset(-r * 0.5, r * 0.5), Offset(-r * 0.5, r * 0.2), sp);
    canvas.drawLine(Offset(r * 0.5, r * 0.5), Offset(r * 0.5, r * 0.2), sp);
  }

  void _drawTorxStar(Canvas canvas, double r, Paint paint) {
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 + math.pi / 6;
      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(angle) * r, math.sin(angle) * r),
        paint,
      );
    }
  }

  void _drawGlowRing(Canvas canvas, double radius) {
    for (int i = 3; i >= 1; i--) {
      canvas.drawCircle(
        Offset.zero,
        radius + i * 4.0,
        Paint()
          ..color = screw.color.withOpacity(0.12 * i)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  void _drawHintRing(Canvas canvas, double radius) {
    canvas.drawCircle(
      Offset.zero,
      radius + 6,
      Paint()
        ..color = AppColors.hintGlow.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      Offset.zero,
      radius + 10,
      Paint()
        ..color = AppColors.hintGlow.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(ScrewPainter old) =>
      old.screw != screw ||
      old.rotationAngle != rotationAngle ||
      old.isHinted != isHinted ||
      old.isGlowing != isGlowing;
}
