import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  BOARD COORDINATE SYSTEM
//
//  The board is divided into a uniform grid.
//  Each cell is [cellSize × cellSize] pixels.
//  Grid origin (0,0) = top-left of board.
// ─────────────────────────────────────────────
class BoardCoordinates {
  final double cellSize;
  final double boardWidth;
  final double boardHeight;
  final int columns;
  final int rows;
  final Offset boardOrigin; // top-left corner of board in screen coords

  const BoardCoordinates({
    required this.cellSize,
    required this.boardWidth,
    required this.boardHeight,
    required this.columns,
    required this.rows,
    this.boardOrigin = Offset.zero,
  });

  /// Compute cell size to fit a given screen size
  factory BoardCoordinates.fromSize({
    required Size screenSize,
    required int columns,
    required int rows,
    double horizontalPadding = 24,
    double verticalPadding = 16,
  }) {
    final availableWidth = screenSize.width - horizontalPadding * 2;
    final availableHeight = screenSize.height * 0.62; // 62% of screen height

    final cellByWidth = availableWidth / columns;
    final cellByHeight = availableHeight / rows;
    final cellSize = cellByWidth.clamp(30, cellByHeight);

    final boardWidth = cellSize * columns;
    final boardHeight = cellSize * rows;
    final originX = (screenSize.width - boardWidth) / 2;
    final originY = screenSize.height * 0.12; // top offset after top bar

    return BoardCoordinates(
      cellSize: cellSize,
      boardWidth: boardWidth,
      boardHeight: boardHeight,
      columns: columns,
      rows: rows,
      boardOrigin: Offset(originX, originY),
    );
  }

  /// Grid cell → pixel center of that cell (relative to board origin)
  Offset cellCenter(Offset gridCell) {
    return Offset(
      gridCell.dx * cellSize + cellSize / 2,
      gridCell.dy * cellSize + cellSize / 2,
    );
  }

  /// Grid cell → pixel center (in screen/canvas coordinates)
  Offset cellCenterGlobal(Offset gridCell) {
    return boardOrigin + cellCenter(gridCell);
  }

  /// Pixel position → grid cell (snapped, may be out of bounds)
  Offset pixelToGrid(Offset pixel) {
    final local = pixel - boardOrigin;
    return Offset(
      (local.dx / cellSize).floorToDouble(),
      (local.dy / cellSize).floorToDouble(),
    );
  }

  /// Returns the Rect for a cell in local board coordinates
  Rect cellRect(Offset gridCell) {
    return Rect.fromLTWH(
      gridCell.dx * cellSize,
      gridCell.dy * cellSize,
      cellSize,
      cellSize,
    );
  }

  /// Returns the Rect for a cell in global screen coordinates
  Rect cellRectGlobal(Offset gridCell) {
    final local = cellRect(gridCell);
    return local.shift(boardOrigin);
  }

  /// Checks if a screen tap hits a given grid cell
  bool isTapOnCell(Offset tapPosition, Offset gridCell) {
    return cellRectGlobal(gridCell).contains(tapPosition);
  }

  /// Checks if a screen position is within the board
  bool isInsideBoard(Offset screenPos) {
    final boardRect =
        Rect.fromLTWH(boardOrigin.dx, boardOrigin.dy, boardWidth, boardHeight);
    return boardRect.contains(screenPos);
  }

  /// Returns the Rect that covers a list of occupied cells (for plate bounds)
  Rect plateRect(List<Offset> occupiedCells) {
    if (occupiedCells.isEmpty) return Rect.zero;
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (final cell in occupiedCells) {
      minX = minX < cell.dx ? minX : cell.dx;
      minY = minY < cell.dy ? minY : cell.dy;
      maxX = maxX > cell.dx ? maxX : cell.dx;
      maxY = maxY > cell.dy ? maxY : cell.dy;
    }
    return Rect.fromLTWH(
      minX * cellSize,
      minY * cellSize,
      (maxX - minX + 1) * cellSize,
      (maxY - minY + 1) * cellSize,
    );
  }
}
