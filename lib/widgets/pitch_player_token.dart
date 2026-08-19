import 'package:flutter/material.dart';

import '../models/player.dart';
import 'player_piece.dart';

/// A single player positioned on the pitch: wraps [PlayerPiece] with its
/// [Positioned] placement and (unless locked or part of a multi-selection
/// group-drag) its own [Draggable] handle.
class PitchPlayerToken extends StatelessWidget {
  const PitchPlayerToken({
    super.key,
    required this.player,
    required this.maxX,
    required this.maxY,
    required this.color,
    required this.overSquadLimit,
    required this.isSelected,
    required this.isGroupSelected,
    required this.jerseyImagePath,
    required this.onTap,
    required this.onDoubleTap,
    required this.onDragEnd,
  });

  final Player player;
  final double maxX;
  final double maxY;
  final Color color;
  final bool overSquadLimit;
  final bool isSelected;

  /// True when this player is a member of an active multi-selection - moved
  /// together via the pitch's group-drag pointer tracking instead of its
  /// own individual [Draggable].
  final bool isGroupSelected;
  final String? jerseyImagePath;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final void Function(DraggableDetails details) onDragEnd;

  @override
  Widget build(BuildContext context) {
    final piece = PlayerPiece(
      player: player,
      isSelected: isSelected,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      color: color,
      jerseyImagePath: jerseyImagePath,
      overSquadLimit: overSquadLimit,
      scale: 1.2,
    );
    return Positioned(
      left: maxX > 0 ? player.x * maxX : 0,
      top: maxY > 0 ? player.y * maxY : 0,
      child: player.locked || isGroupSelected
          ? piece
          : Draggable<Player>(
              data: player,
              dragAnchorStrategy: pointerDragAnchorStrategy,
              feedback: PlayerPiece.centeredFeedback(
                child: Opacity(
                  opacity: 0.85,
                  child: PlayerPiece(
                    player: player,
                    isSelected: true,
                    onTap: () {},
                    color: color,
                    jerseyImagePath: jerseyImagePath,
                    overSquadLimit: overSquadLimit,
                    scale: 1.2,
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: PlayerPiece(
                  player: player,
                  isSelected: false,
                  onTap: () {},
                  color: color,
                  jerseyImagePath: jerseyImagePath,
                  overSquadLimit: overSquadLimit,
                  scale: 1.2,
                ),
              ),
              onDragEnd: onDragEnd,
              child: piece,
            ),
    );
  }
}
