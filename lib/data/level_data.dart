import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../utils/app_theme.dart';

// ─────────────────────────────────────────────
//  LEVEL DATA REGISTRY
//  Each level is hand-designed using a grid
//  coordinate system. (0,0) = top-left.
// ─────────────────────────────────────────────
class LevelData {
  LevelData._();

  static LevelModel level1() {
    // ── Plates ──────────────────────────────
    final plates = [
      PlateModel(
        id: 'p1',
        shape: PlateShape.rectangle,
        color: AppColors.plateCyan,
        originCell: const Offset(0, 0),
        occupiedCells: [
          const Offset(0, 0), const Offset(1, 0),
          const Offset(0, 1), const Offset(1, 1),
        ],
        activeScrewIds: {'s1', 's2'},
        zLayer: 1,
      ),
      PlateModel(
        id: 'p2',
        shape: PlateShape.rectangle,
        color: AppColors.plateLime,
        originCell: const Offset(2, 1),
        occupiedCells: [
          const Offset(2, 1), const Offset(3, 1),
          const Offset(2, 2), const Offset(3, 2),
        ],
        activeScrewIds: {'s3'},
        zLayer: 2,
      ),
      PlateModel(
        id: 'p3',
        shape: PlateShape.wide,
        color: AppColors.plateYellow,
        originCell: const Offset(0, 3),
        occupiedCells: [
          const Offset(0, 3), const Offset(1, 3),
          const Offset(2, 3), const Offset(3, 3),
        ],
        activeScrewIds: {'s4', 's5'},
        zLayer: 1,
      ),
    ];

    // ── Screws ───────────────────────────────
    final screws = [
      ScrewModel(
        id: 's1',
        boardPosition: const Offset(0, 0),
        color: AppColors.screwGold,
        headType: ScrewHeadType.hex,
        pinnedPlateIds: ['p1'],
      ),
      ScrewModel(
        id: 's2',
        boardPosition: const Offset(1, 1),
        color: AppColors.screwSilver,
        headType: ScrewHeadType.phillips,
        pinnedPlateIds: ['p1'],
      ),
      ScrewModel(
        id: 's3',
        boardPosition: const Offset(3, 2),
        color: AppColors.screwRoseGold,
        headType: ScrewHeadType.hex,
        pinnedPlateIds: ['p2'],
      ),
      ScrewModel(
        id: 's4',
        boardPosition: const Offset(0, 3),
        color: AppColors.screwGold,
        headType: ScrewHeadType.torx,
        pinnedPlateIds: ['p3'],
      ),
      ScrewModel(
        id: 's5',
        boardPosition: const Offset(3, 3),
        color: AppColors.screwSilver,
        headType: ScrewHeadType.flathead,
        pinnedPlateIds: ['p3'],
      ),
    ];

    // ── Holes ────────────────────────────────
    final holes = List.generate(
      6,
      (i) => HoleModel(
        id: 'h$i',
        gridPosition: Offset(i.toDouble(), 5),
      ),
    );

    return LevelModel(
      levelNumber: 1,
      gridColumns: 5,
      gridRows: 6,
      plates: plates,
      screws: screws,
      holes: holes,
      parMoves: 5,
      hintText: 'Remove the cyan plate screws first!',
    );
  }

  static LevelModel level2() {
    final plates = [
      // Overlapping plates: ruby is under cyan
      PlateModel(
        id: 'p1',
        shape: PlateShape.rectangle,
        color: AppColors.plateCyan,
        originCell: const Offset(1, 0),
        occupiedCells: [
          const Offset(1, 0), const Offset(2, 0),
          const Offset(1, 1), const Offset(2, 1),
        ],
        activeScrewIds: {'s1', 's2'},
        zLayer: 3,
      ),
      PlateModel(
        id: 'p2',
        shape: PlateShape.lShape,
        color: AppColors.plateRuby,
        originCell: const Offset(0, 1),
        occupiedCells: [
          const Offset(0, 1),
          const Offset(1, 1), const Offset(2, 1), const Offset(3, 1),
          const Offset(3, 2),
        ],
        activeScrewIds: {'s3', 's4'},
        zLayer: 2,
      ),
      PlateModel(
        id: 'p3',
        shape: PlateShape.rectangle,
        color: AppColors.plateLime,
        originCell: const Offset(0, 3),
        occupiedCells: [
          const Offset(0, 3), const Offset(1, 3),
          const Offset(0, 4), const Offset(1, 4),
        ],
        activeScrewIds: {'s5'},
        zLayer: 1,
      ),
      PlateModel(
        id: 'p4',
        shape: PlateShape.square,
        color: AppColors.plateOrange,
        originCell: const Offset(3, 3),
        occupiedCells: [
          const Offset(3, 3),
          const Offset(3, 4),
        ],
        activeScrewIds: {'s6'},
        zLayer: 1,
      ),
    ];

    final screws = [
      ScrewModel(
        id: 's1',
        boardPosition: const Offset(1, 0),
        color: AppColors.screwGold,
        headType: ScrewHeadType.hex,
        pinnedPlateIds: ['p1'],
      ),
      ScrewModel(
        id: 's2',
        boardPosition: const Offset(2, 1),
        color: AppColors.screwRoseGold,
        headType: ScrewHeadType.phillips,
        pinnedPlateIds: ['p1', 'p2'], // pins TWO plates
      ),
      ScrewModel(
        id: 's3',
        boardPosition: const Offset(0, 1),
        color: AppColors.screwSilver,
        headType: ScrewHeadType.flathead,
        pinnedPlateIds: ['p2'],
      ),
      ScrewModel(
        id: 's4',
        boardPosition: const Offset(3, 2),
        color: AppColors.screwGold,
        headType: ScrewHeadType.torx,
        pinnedPlateIds: ['p2'],
      ),
      ScrewModel(
        id: 's5',
        boardPosition: const Offset(0, 4),
        color: AppColors.screwRoseGold,
        headType: ScrewHeadType.hex,
        pinnedPlateIds: ['p3'],
      ),
      ScrewModel(
        id: 's6',
        boardPosition: const Offset(3, 3),
        color: AppColors.screwSilver,
        headType: ScrewHeadType.phillips,
        pinnedPlateIds: ['p4'],
      ),
    ];

    final holes = List.generate(
      8,
      (i) => HoleModel(
        id: 'h$i',
        gridPosition: Offset((i % 4).toDouble(), 5 + (i ~/ 4)),
      ),
    );

    return LevelModel(
      levelNumber: 2,
      gridColumns: 5,
      gridRows: 7,
      plates: plates,
      screws: screws,
      holes: holes,
      parMoves: 6,
      hintText: 'Note: some screws lock multiple plates!',
    );
  }

  static LevelModel level3() {
    final plates = [
      PlateModel(
        id: 'p1',
        shape: PlateShape.tShape,
        color: AppColors.platePurple,
        originCell: const Offset(1, 0),
        occupiedCells: [
          const Offset(1, 0), const Offset(2, 0), const Offset(3, 0),
                              const Offset(2, 1),
                              const Offset(2, 2),
        ],
        activeScrewIds: {'s1', 's2', 's3'},
        zLayer: 3,
      ),
      PlateModel(
        id: 'p2',
        shape: PlateShape.wide,
        color: AppColors.plateCyan,
        originCell: const Offset(0, 2),
        occupiedCells: [
          const Offset(0, 2), const Offset(1, 2),
          const Offset(2, 2), const Offset(3, 2), const Offset(4, 2),
        ],
        activeScrewIds: {'s4', 's5'},
        zLayer: 2,
      ),
      PlateModel(
        id: 'p3',
        shape: PlateShape.rectangle,
        color: AppColors.plateYellow,
        originCell: const Offset(0, 3),
        occupiedCells: [
          const Offset(0, 3), const Offset(1, 3),
          const Offset(0, 4), const Offset(1, 4),
        ],
        activeScrewIds: {'s6'},
        zLayer: 1,
      ),
      PlateModel(
        id: 'p4',
        shape: PlateShape.rectangle,
        color: AppColors.plateRuby,
        originCell: const Offset(3, 3),
        occupiedCells: [
          const Offset(3, 3), const Offset(4, 3),
          const Offset(3, 4), const Offset(4, 4),
        ],
        activeScrewIds: {'s7', 's8'},
        zLayer: 1,
      ),
    ];

    final screws = [
      ScrewModel(id: 's1', boardPosition: const Offset(1, 0), color: AppColors.screwGold, headType: ScrewHeadType.hex, pinnedPlateIds: ['p1']),
      ScrewModel(id: 's2', boardPosition: const Offset(3, 0), color: AppColors.screwSilver, headType: ScrewHeadType.torx, pinnedPlateIds: ['p1']),
      ScrewModel(id: 's3', boardPosition: const Offset(2, 2), color: AppColors.screwRoseGold, headType: ScrewHeadType.phillips, pinnedPlateIds: ['p1', 'p2']),
      ScrewModel(id: 's4', boardPosition: const Offset(0, 2), color: AppColors.screwGold, headType: ScrewHeadType.flathead, pinnedPlateIds: ['p2']),
      ScrewModel(id: 's5', boardPosition: const Offset(4, 2), color: AppColors.screwSilver, headType: ScrewHeadType.hex, pinnedPlateIds: ['p2']),
      ScrewModel(id: 's6', boardPosition: const Offset(1, 4), color: AppColors.screwRoseGold, headType: ScrewHeadType.torx, pinnedPlateIds: ['p3']),
      ScrewModel(id: 's7', boardPosition: const Offset(3, 3), color: AppColors.screwGold, headType: ScrewHeadType.phillips, pinnedPlateIds: ['p4']),
      ScrewModel(id: 's8', boardPosition: const Offset(4, 4), color: AppColors.screwSilver, headType: ScrewHeadType.flathead, pinnedPlateIds: ['p4']),
    ];

    final holes = List.generate(
      10,
      (i) => HoleModel(
        id: 'h$i',
        gridPosition: Offset((i % 5).toDouble(), 5 + (i ~/ 5)),
      ),
    );

    return LevelModel(
      levelNumber: 3,
      gridColumns: 5,
      gridRows: 7,
      plates: plates,
      screws: screws,
      holes: holes,
      parMoves: 8,
      hintText: 'Clear the T-shaped purple plate first to unlock cyan.',
    );
  }

  static List<LevelModel> get allLevels => [level1(), level2(), level3()];
}
