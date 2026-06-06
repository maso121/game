import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

// ─────────────────────────────────────────────
//  SCREW MODEL
// ─────────────────────────────────────────────
enum ScrewHeadType { hex, flathead, phillips, torx }

enum ScrewState { screwed, unscrewing, unscrewed, flying }

class ScrewModel extends Equatable {
  final String id;
  final Offset boardPosition; // grid coordinate (col, row)
  final Color color;
  final ScrewHeadType headType;
  final ScrewState state;
  final List<String> pinnedPlateIds; // plate IDs this screw pins
  final String? currentHoleId; // null = on a plate, non-null = in a hole

  const ScrewModel({
    required this.id,
    required this.boardPosition,
    required this.color,
    this.headType = ScrewHeadType.hex,
    this.state = ScrewState.screwed,
    this.pinnedPlateIds = const [],
    this.currentHoleId,
  });

  bool get isActive => state == ScrewState.screwed;
  bool get canInteract => state == ScrewState.screwed;

  ScrewModel copyWith({
    String? id,
    Offset? boardPosition,
    Color? color,
    ScrewHeadType? headType,
    ScrewState? state,
    List<String>? pinnedPlateIds,
    String? currentHoleId,
    bool clearHoleId = false,
  }) {
    return ScrewModel(
      id: id ?? this.id,
      boardPosition: boardPosition ?? this.boardPosition,
      color: color ?? this.color,
      headType: headType ?? this.headType,
      state: state ?? this.state,
      pinnedPlateIds: pinnedPlateIds ?? this.pinnedPlateIds,
      currentHoleId: clearHoleId ? null : (currentHoleId ?? this.currentHoleId),
    );
  }

  @override
  List<Object?> get props => [
        id,
        boardPosition,
        color,
        headType,
        state,
        pinnedPlateIds,
        currentHoleId,
      ];
}

// ─────────────────────────────────────────────
//  PLATE MODEL
// ─────────────────────────────────────────────
enum PlateShape { rectangle, lShape, tShape, square, wide, tall }

enum PlateState { locked, free, falling, cleared }

class PlateModel extends Equatable {
  final String id;
  final PlateShape shape;
  final Color color;
  final Offset originCell; // top-left grid cell
  final List<Offset> occupiedCells; // relative to originCell
  final Set<String> activeScrewIds; // screws currently pinning this plate
  final PlateState state;
  final int zLayer; // render order (higher = on top)

  const PlateModel({
    required this.id,
    required this.shape,
    required this.color,
    required this.originCell,
    required this.occupiedCells,
    required this.activeScrewIds,
    this.state = PlateState.locked,
    this.zLayer = 0,
  });

  /// A plate is locked if it has at least one active screw
  bool get isLocked => activeScrewIds.isNotEmpty;

  /// True when all screws removed and plate can fall
  bool get isFree => state == PlateState.free;

  PlateModel copyWith({
    String? id,
    PlateShape? shape,
    Color? color,
    Offset? originCell,
    List<Offset>? occupiedCells,
    Set<String>? activeScrewIds,
    PlateState? state,
    int? zLayer,
  }) {
    return PlateModel(
      id: id ?? this.id,
      shape: shape ?? this.shape,
      color: color ?? this.color,
      originCell: originCell ?? this.originCell,
      occupiedCells: occupiedCells ?? this.occupiedCells,
      activeScrewIds: activeScrewIds ?? this.activeScrewIds,
      state: state ?? this.state,
      zLayer: zLayer ?? this.zLayer,
    );
  }

  @override
  List<Object?> get props => [
        id,
        shape,
        color,
        originCell,
        occupiedCells,
        activeScrewIds,
        state,
        zLayer,
      ];
}

// ─────────────────────────────────────────────
//  HOLE MODEL  (empty slots on the base plate)
// ─────────────────────────────────────────────
class HoleModel extends Equatable {
  final String id;
  final Offset gridPosition;
  final bool isOccupied;
  final String? occupyingScrewId;

  const HoleModel({
    required this.id,
    required this.gridPosition,
    this.isOccupied = false,
    this.occupyingScrewId,
  });

  HoleModel copyWith({
    String? id,
    Offset? gridPosition,
    bool? isOccupied,
    String? occupyingScrewId,
    bool clearScrew = false,
  }) {
    return HoleModel(
      id: id ?? this.id,
      gridPosition: gridPosition ?? this.gridPosition,
      isOccupied: isOccupied ?? this.isOccupied,
      occupyingScrewId:
          clearScrew ? null : (occupyingScrewId ?? this.occupyingScrewId),
    );
  }

  @override
  List<Object?> get props => [id, gridPosition, isOccupied, occupyingScrewId];
}

// ─────────────────────────────────────────────
//  LEVEL MODEL
// ─────────────────────────────────────────────
class LevelModel extends Equatable {
  final int levelNumber;
  final int gridColumns;
  final int gridRows;
  final List<PlateModel> plates;
  final List<ScrewModel> screws;
  final List<HoleModel> holes;
  final int parMoves; // ideal move count (for star rating)
  final String? hintText;

  const LevelModel({
    required this.levelNumber,
    required this.gridColumns,
    required this.gridRows,
    required this.plates,
    required this.screws,
    required this.holes,
    this.parMoves = 10,
    this.hintText,
  });

  /// Total screws that must be removed to complete level
  int get totalScrews => screws.length;

  /// Check if all plates are cleared
  bool get isComplete =>
      plates.every((p) => p.state == PlateState.cleared);

  @override
  List<Object?> get props => [
        levelNumber,
        gridColumns,
        gridRows,
        plates,
        screws,
        holes,
        parMoves,
        hintText,
      ];
}

// ─────────────────────────────────────────────
//  GAME STATE MODEL
// ─────────────────────────────────────────────
enum GamePhase { playing, levelComplete, paused, failed }

class GameStateModel extends Equatable {
  final LevelModel level;
  final List<ScrewModel> screws;
  final List<PlateModel> plates;
  final List<HoleModel> holes;
  final int moveCount;
  final GamePhase phase;
  final List<String> moveHistory; // screw IDs in order (for undo)
  final int hintsRemaining;

  const GameStateModel({
    required this.level,
    required this.screws,
    required this.plates,
    required this.holes,
    this.moveCount = 0,
    this.phase = GamePhase.playing,
    this.moveHistory = const [],
    this.hintsRemaining = 3,
  });

  /// Find screw by ID
  ScrewModel? screwById(String id) =>
      screws.firstWhereOrNull((s) => s.id == id);

  /// Find plate by ID
  PlateModel? plateById(String id) =>
      plates.firstWhereOrNull((p) => p.id == id);

  /// Find available hole (not occupied)
  HoleModel? nextFreeHole() =>
      holes.firstWhereOrNull((h) => !h.isOccupied);

  /// Count cleared plates
  int get clearedPlates => plates.where((p) => p.state == PlateState.cleared).length;

  /// Star rating (1–3)
  int get starRating {
    if (moveCount <= level.parMoves) return 3;
    if (moveCount <= level.parMoves * 1.5) return 2;
    return 1;
  }

  GameStateModel copyWith({
    LevelModel? level,
    List<ScrewModel>? screws,
    List<PlateModel>? plates,
    List<HoleModel>? holes,
    int? moveCount,
    GamePhase? phase,
    List<String>? moveHistory,
    int? hintsRemaining,
  }) {
    return GameStateModel(
      level: level ?? this.level,
      screws: screws ?? this.screws,
      plates: plates ?? this.plates,
      holes: holes ?? this.holes,
      moveCount: moveCount ?? this.moveCount,
      phase: phase ?? this.phase,
      moveHistory: moveHistory ?? this.moveHistory,
      hintsRemaining: hintsRemaining ?? this.hintsRemaining,
    );
  }

  @override
  List<Object?> get props => [
        level,
        screws,
        plates,
        holes,
        moveCount,
        phase,
        moveHistory,
        hintsRemaining,
      ];
}
