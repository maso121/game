import 'dart:math' as math;
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════
//  PHYSICS MATH UTILITIES
//  Pure Dart math for simulated gravity, spring forces, and easing.
//  No Forge2D dependency — everything runs on Flutter's Ticker.
// ═══════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────
//  PLATE FALL PHYSICS PARAMETERS
// ─────────────────────────────────────────────

/// Describes the simulated rigid-body fall for a freed plate.
/// Each plate gets a unique [FallProfile] calculated at the
/// moment its last screw is removed.
class FallProfile {
  /// Linear acceleration (pixels/s²). Simulates gravity.
  final double gravityPps2;

  /// Initial horizontal velocity (pixels/s) — the "swing" direction.
  final double initialVx;

  /// Initial angular velocity (radians/s). Positive = clockwise.
  final double initialOmega;

  /// Angular damping (radians/s²) — slows spin over time.
  final double angularDamping;

  /// How long the full fall animation lasts (ms).
  final int durationMs;

  const FallProfile({
    required this.gravityPps2,
    required this.initialVx,
    required this.initialOmega,
    required this.angularDamping,
    required this.durationMs,
  });

  /// Factory: compute a natural fall profile for a plate given its
  /// board position.  Plates on the left swing left; right swing right.
  factory FallProfile.forPlate({
    required double normalizedX, // 0.0 = far left, 1.0 = far right
    double? overrideGravity,
  }) {
    final random = _seededRandom(normalizedX);
    final isLeft = normalizedX < 0.5;
    final swingSign = isLeft ? -1.0 : 1.0;

    return FallProfile(
      gravityPps2: overrideGravity ?? (820 + random * 180),
      initialVx: swingSign * (80 + random * 120),
      initialOmega: swingSign * (0.8 + random * 1.2),
      angularDamping: 0.6 + random * 0.4,
      durationMs: (680 + (random * 220).toInt()),
    );
  }

  /// Lightweight pseudo-random from a deterministic seed (for replay).
  static double _seededRandom(double seed) {
    final x = math.sin(seed * 127.1 + 311.7) * 43758.5453;
    return x - x.floor();
  }
}

// ─────────────────────────────────────────────
//  PLATE PHYSICS STATE  (mutable, per-frame)
// ─────────────────────────────────────────────

/// Accumulated physics state, updated every frame during fall.
class PlatePhysicsState {
  double x; // horizontal displacement (px)
  double y; // vertical displacement (px)
  double angle; // rotation (radians)
  double vx; // horizontal velocity (px/s)
  double vy; // vertical velocity (px/s)
  double omega; // angular velocity (rad/s)
  double opacity; // fades to 0 in last 40% of fall

  PlatePhysicsState({
    this.x = 0,
    this.y = 0,
    this.angle = 0,
    this.vx = 0,
    this.vy = 0,
    this.omega = 0,
    this.opacity = 1.0,
  });

  /// Step the simulation by [dt] seconds using the given [FallProfile].
  void step(double dt, FallProfile profile, double totalElapsed, double totalDuration) {
    // Integrate velocities
    vy += profile.gravityPps2 * dt;
    omega -= omega * profile.angularDamping * dt;

    x += vx * dt;
    y += vy * dt;
    angle += omega * dt;

    // Fade out in the last 40%
    final progress = (totalElapsed / totalDuration).clamp(0.0, 1.0);
    opacity = progress < 0.60 ? 1.0 : (1.0 - (progress - 0.60) / 0.40).clamp(0.0, 1.0);
  }

  static PlatePhysicsState fromProfile(FallProfile p) => PlatePhysicsState(
        vx: p.initialVx,
        vy: -40, // tiny upward bounce at start (realistic for sudden release)
        omega: p.initialOmega,
      );
}

// ─────────────────────────────────────────────
//  SCREW FLY PHYSICS  (screw travels to hole)
// ─────────────────────────────────────────────

/// Calculates the Bézier control points for a screw flying from its
/// plate position to a target hole position.
class ScrewFlyPath {
  final Offset start;
  final Offset end;
  final Offset control; // quadratic Bézier control point

  ScrewFlyPath({required this.start, required this.end})
      : control = _computeControl(start, end);

  static Offset _computeControl(Offset s, Offset e) {
    // Arc up then down toward the target
    final mid = Offset((s.dx + e.dx) / 2, (s.dy + e.dy) / 2);
    final perpOffset = Offset(-(e.dy - s.dy), e.dx - s.dx).normalize() * 60;
    return mid - perpOffset;
  }

  /// Evaluate position at parameter t ∈ [0, 1]
  Offset evaluate(double t) {
    final mt = 1 - t;
    return Offset(
      mt * mt * start.dx + 2 * mt * t * control.dx + t * t * end.dx,
      mt * mt * start.dy + 2 * mt * t * control.dy + t * t * end.dy,
    );
  }

  /// Tangent angle at t (for rotating the screw along path)
  double tangentAngle(double t) {
    final mt = 1 - t;
    final dx = 2 * (mt * (control.dx - start.dx) + t * (end.dx - control.dx));
    final dy = 2 * (mt * (control.dy - start.dy) + t * (end.dy - control.dy));
    return math.atan2(dy, dx);
  }
}

// ─────────────────────────────────────────────
//  SPRING INTERPOLATION  (bounce-settle)
// ─────────────────────────────────────────────

/// Damped spring model for UI micro-bounce effects.
/// Used for the screw "arriving in hole" settle animation.
class SpringValue {
  double _value;
  double _velocity;
  final double stiffness;
  final double damping;
  final double target;

  SpringValue({
    required double initial,
    required this.target,
    this.stiffness = 300,
    this.damping = 28,
  })  : _value = initial,
        _velocity = 0;

  double get value => _value;
  bool get isSettled => (_value - target).abs() < 0.001 && _velocity.abs() < 0.01;

  void step(double dt) {
    final force = -stiffness * (_value - target) - damping * _velocity;
    _velocity += force * dt;
    _value += _velocity * dt;
  }
}

// ─────────────────────────────────────────────
//  SHAKE ANIMATION  (wrong-move feedback)
// ─────────────────────────────────────────────

/// Generates a decaying sinusoidal shake offset.
/// Call [valueAt(t)] where t ∈ [0, 1].
class ShakeAnimation {
  final double amplitude;
  final int oscillations;

  const ShakeAnimation({
    this.amplitude = 8.0,
    this.oscillations = 4,
  });

  Offset valueAt(double t) {
    final decay = 1.0 - t;
    final x = amplitude * decay * math.sin(t * oscillations * math.pi * 2);
    return Offset(x, 0);
  }
}

// ─────────────────────────────────────────────
//  EXTENSION: Offset normalize
// ─────────────────────────────────────────────
extension OffsetExtensions on Offset {
  double get magnitude => math.sqrt(dx * dx + dy * dy);

  Offset normalize() {
    final m = magnitude;
    if (m == 0) return Offset.zero;
    return Offset(dx / m, dy / m);
  }

  Offset operator *(double scalar) => Offset(dx * scalar, dy * scalar);

  /// Linear interpolation toward [other] by factor [t]
  Offset lerp(Offset other, double t) =>
      Offset(dx + (other.dx - dx) * t, dy + (other.dy - dy) * t);

  /// Rotates this offset by [angle] radians around origin
  Offset rotate(double angle) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    return Offset(dx * cosA - dy * sinA, dx * sinA + dy * cosA);
  }
}

// ─────────────────────────────────────────────
//  CURVE UTILITIES
// ─────────────────────────────────────────────

/// Custom elastic-out curve with controllable overshoot.
class ElasticOutCustom extends Curve {
  final double period;
  final double amplitude;

  const ElasticOutCustom({this.period = 0.4, this.amplitude = 1.0});

  @override
  double transformInternal(double t) {
    if (t == 0 || t == 1) return t;
    final s = period / 4.0;
    return amplitude *
            math.pow(2, -10 * t) *
            math.sin((t - s) * (2 * math.pi) / period) +
        1.0;
  }
}

/// Gravity drop curve: starts slow, accelerates dramatically.
class GravityCurve extends Curve {
  const GravityCurve();

  @override
  double transformInternal(double t) => t * t * (2.4 - t * 1.4);
}

/// Anticipation curve: slight pull-back before forward motion.
class AnticipationCurve extends Curve {
  final double overshoot;
  const AnticipationCurve({this.overshoot = 1.2});

  @override
  double transformInternal(double t) {
    return t * t * ((overshoot + 1) * t - overshoot);
  }
}

// ─────────────────────────────────────────────
//  SCREW ROTATION CURVES
// ─────────────────────────────────────────────

/// Maps animation progress → total rotation angle (in radians).
/// Simulates real unscrewing: slow start, fast middle, slow finish.
double screwRotationAngle(double t, {double totalTurns = 3.5}) {
  // S-curve: ease-in then linear
  final shaped = t < 0.3
      ? (t / 0.3) * (t / 0.3) * 0.3 // quadratic ease-in for first 30%
      : 0.3 + (t - 0.3) * (1.0 / 0.7) * 0.7; // linear for rest
  return shaped * totalTurns * 2 * math.pi;
}

/// Vertical lift offset during unscrewing (rises as it rotates).
double screwLiftOffset(double t, double cellSize) {
  // Rises proportionally, then shoots off at the end
  if (t < 0.75) {
    return -t * cellSize * 0.3;
  } else {
    final endT = (t - 0.75) / 0.25;
    return -cellSize * 0.225 - endT * endT * cellSize * 1.8;
  }
}

/// Scale factor during unscrewing (grows slightly as it rises).
double screwScale(double t) {
  if (t < 0.5) return 1.0 + t * 0.15;
  return 1.075 - (t - 0.5) * 0.6;
}
