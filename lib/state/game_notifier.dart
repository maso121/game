import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_models.dart';
import '../data/level_data.dart';

// ─────────────────────────────────────────────
//  PROVIDERS
// ─────────────────────────────────────────────

/// Current level index (0-based)
final currentLevelIndexProvider = StateProvider<int>((ref) => 0);

/// Resolved level model for current index
final currentLevelProvider = Provider<LevelModel>((ref) {
  final idx = ref.watch(currentLevelIndexProvider);
  return LevelData.allLevels[idx.clamp(0, LevelData.allLevels.length - 1)];
});

/// Main game state notifier
final gameStateProvider =
    StateNotifierProvider<GameNotifier, GameStateModel>((ref) {
  final level = ref.watch(currentLevelProvider);
  return GameNotifier(level);
});

// ─────────────────────────────────────────────
//  GAME NOTIFIER
// ─────────────────────────────────────────────
class GameNotifier extends StateNotifier<GameStateModel> {
  GameNotifier(LevelModel level)
      : super(GameStateModel(
          level: level,
          screws: level.screws,
          plates: level.plates,
          holes: level.holes,
          hintsRemaining: 3,
        ));

  // ── Public API ────────────────────────────

  /// Called when the player taps a screw
  /// Returns true if the tap was handled (screw was free to remove)
  bool onScrewTapped(String screwId) {
    if (state.phase != GamePhase.playing) return false;

    final screw = state.screwById(screwId);
    if (screw == null || !screw.canInteract) return false;

    // Start unscrewing animation state
    _beginUnscrewing(screwId);
    return true;
  }

  /// Called when unscrewing animation completes — finalizes the move
  void onUnscrewComplete(String screwId) {
    final screw = state.screwById(screwId);
    if (screw == null) return;

    // Find a free hole to place the screw
    final freeHole = state.nextFreeHole();

    // Update screw: mark as unscrewed, assign to hole
    final updatedScrews = state.screws.map((s) {
      if (s.id == screwId) {
        return s.copyWith(
          state: freeHole != null ? ScrewState.unscrewed : ScrewState.flying,
          boardPosition:
              freeHole?.gridPosition ?? const Offset(-1, -1),
          currentHoleId: freeHole?.id,
        );
      }
      return s;
    }).toList();

    // Update the hole occupancy
    final updatedHoles = state.holes.map((h) {
      if (h.id == freeHole?.id) {
        return h.copyWith(isOccupied: true, occupyingScrewId: screwId);
      }
      return h;
    }).toList();

    // Remove screw from all plates it was pinning
    final pinnedPlateIds = screw.pinnedPlateIds;
    var updatedPlates = state.plates.map((plate) {
      if (pinnedPlateIds.contains(plate.id)) {
        final newScrewIds =
            Set<String>.from(plate.activeScrewIds)..remove(screwId);
        final newState =
            newScrewIds.isEmpty ? PlateState.free : PlateState.locked;
        return plate.copyWith(
          activeScrewIds: newScrewIds,
          state: newState,
        );
      }
      return plate;
    }).toList();

    final newMoveCount = state.moveCount + 1;
    final newHistory = [...state.moveHistory, screwId];

    state = state.copyWith(
      screws: updatedScrews,
      plates: updatedPlates,
      holes: updatedHoles,
      moveCount: newMoveCount,
      moveHistory: newHistory,
    );

    // Check if level complete (deferred — plates may still be animating)
    _checkWinCondition();
  }

  /// Called when a plate's fall animation completes
  void onPlateFallComplete(String plateId) {
    final updatedPlates = state.plates.map((p) {
      if (p.id == plateId) return p.copyWith(state: PlateState.cleared);
      return p;
    }).toList();

    state = state.copyWith(plates: updatedPlates);
    _checkWinCondition();
  }

  /// Undo the last move
  bool undoLastMove() {
    if (state.moveHistory.isEmpty || state.phase != GamePhase.playing) {
      return false;
    }

    final lastScrewId = state.moveHistory.last;

    // Find original screw data from level definition
    final originalScrew =
        state.level.screws.firstWhere((s) => s.id == lastScrewId);

    // Restore screw to original screwed state
    final updatedScrews = state.screws.map((s) {
      if (s.id == lastScrewId) {
        return originalScrew.copyWith(state: ScrewState.screwed);
      }
      return s;
    }).toList();

    // Free the hole it was in
    final updatedHoles = state.holes.map((h) {
      if (h.occupyingScrewId == lastScrewId) {
        return h.copyWith(isOccupied: false, clearScrew: true);
      }
      return h;
    }).toList();

    // Re-lock plates that this screw was pinning
    final updatedPlates = state.plates.map((plate) {
      if (originalScrew.pinnedPlateIds.contains(plate.id)) {
        final restoredScrews =
            Set<String>.from(plate.activeScrewIds)..add(lastScrewId);
        return plate.copyWith(
          activeScrewIds: restoredScrews,
          state: PlateState.locked,
        );
      }
      return plate;
    }).toList();

    state = state.copyWith(
      screws: updatedScrews,
      plates: updatedPlates,
      holes: updatedHoles,
      moveCount: (state.moveCount - 1).clamp(0, 9999),
      moveHistory: state.moveHistory.sublist(0, state.moveHistory.length - 1),
      phase: GamePhase.playing,
    );

    return true;
  }

  /// Reset the current level to its initial state
  void resetLevel() {
    final level = state.level;
    state = GameStateModel(
      level: level,
      screws: level.screws,
      plates: level.plates,
      holes: level.holes,
      hintsRemaining: state.hintsRemaining,
    );
  }

  /// Use a hint — returns the ID of the recommended next screw to tap, or null
  String? useHint() {
    if (state.hintsRemaining <= 0) return null;

    // Strategy: find the screw whose removal frees the most plates
    final freeable = _findBestNextScrew();
    if (freeable == null) return null;

    state = state.copyWith(
      hintsRemaining: state.hintsRemaining - 1,
    );

    return freeable;
  }

  void togglePause() {
    if (state.phase == GamePhase.playing) {
      state = state.copyWith(phase: GamePhase.paused);
    } else if (state.phase == GamePhase.paused) {
      state = state.copyWith(phase: GamePhase.playing);
    }
  }

  // ── Private helpers ───────────────────────

  void _beginUnscrewing(String screwId) {
    final updatedScrews = state.screws.map((s) {
      if (s.id == screwId) return s.copyWith(state: ScrewState.unscrewing);
      return s;
    }).toList();
    state = state.copyWith(screws: updatedScrews);
  }

  void _checkWinCondition() {
    // Win only after all plates are cleared (not just free)
    final allCleared =
        state.plates.every((p) => p.state == PlateState.cleared);
    if (allCleared) {
      state = state.copyWith(phase: GamePhase.levelComplete);
    }
  }

  /// Heuristic: pick the screw pinning the most locked plates,
  /// that itself is interactable right now
  String? _findBestNextScrew() {
    // Map: screwId → number of plates it would free
    final Map<String, int> freedCount = {};

    for (final screw in state.screws) {
      if (!screw.canInteract) continue;
      int freed = 0;
      for (final plateId in screw.pinnedPlateIds) {
        final plate = state.plateById(plateId);
        if (plate != null &&
            plate.state == PlateState.locked &&
            plate.activeScrewIds.length == 1) {
          // Removing this screw would fully free this plate
          freed++;
        }
      }
      freedCount[screw.id] = freed;
    }

    if (freedCount.isEmpty) return null;

    // Return screw that frees the most plates
    return freedCount.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }
}

// ─────────────────────────────────────────────
//  DERIVED PROVIDERS
// ─────────────────────────────────────────────

/// Plates sorted by z-layer for rendering
final sortedPlatesProvider = Provider<List<PlateModel>>((ref) {
  final gs = ref.watch(gameStateProvider);
  final plates = List<PlateModel>.from(gs.plates);
  plates.sort((a, b) => a.zLayer.compareTo(b.zLayer));
  return plates;
});

/// Only screws that are in the 'screwed' or 'unscrewing' state
final activeScrewsProvider = Provider<List<ScrewModel>>((ref) {
  final gs = ref.watch(gameStateProvider);
  return gs.screws
      .where((s) =>
          s.state == ScrewState.screwed || s.state == ScrewState.unscrewing)
      .toList();
});

/// Screws now residing in holes
final holesScrewsProvider = Provider<List<ScrewModel>>((ref) {
  final gs = ref.watch(gameStateProvider);
  return gs.screws
      .where((s) => s.state == ScrewState.unscrewed)
      .toList();
});

/// Game completion provider
final isLevelCompleteProvider = Provider<bool>((ref) {
  return ref.watch(gameStateProvider).phase == GamePhase.levelComplete;
});

/// Hint screw ID (null if no hint active)
final hintScrewIdProvider = StateProvider<String?>((ref) => null);
