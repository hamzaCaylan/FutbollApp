import 'package:flutter/material.dart';

import '../models/player.dart';

class PlayerPiece extends StatelessWidget {
  const PlayerPiece({
    super.key,
    required this.player,
    required this.onTap,
    required this.isSelected,
    required this.color,
    this.onDoubleTap,
    this.jerseyImagePath,
    this.overSquadLimit = false,
    this.scale = 1.0,
  });

  final Player player;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final bool isSelected;

  /// When set, the avatar renders this jersey artwork (cropped to the
  /// circle) with the player's number over it, instead of the plain
  /// number-in-circle look. Chosen from the Ayarlar dialog.
  final String? jerseyImagePath;

  /// True when this player was dragged onto the pitch past the team's
  /// configured squad size (Ayarlar) - rings the avatar in a translucent
  /// red warning circle instead of silently allowing an oversized lineup.
  final bool overSquadLimit;

  /// The team's ring color around the avatar.
  final Color color;

  /// Visually enlarges just the avatar (ring/jersey/badges), leaving the
  /// name label and the widget's own layout size (used for pitch hit-test/
  /// positioning math) untouched. Used to make pitch jerseys read a bit
  /// bigger than bench ones without needing separate layout constants.
  final double scale;

  static const double size = 56;

  /// Width the piece is centered within for drag feedback purposes; must
  /// match the pill label's max width below so the avatar's true horizontal
  /// center is predictable regardless of how long the player's name is.
  static const double _feedbackWidth = 88;

  /// Wraps drag feedback so the piece's circle is centered under the
  /// pointer instead of `pointerDragAnchorStrategy`'s default of pinning the
  /// widget's top-left corner to the cursor.
  static Widget centeredFeedback({required Widget child}) {
    return Transform.translate(
      offset: const Offset(-_feedbackWidth / 2, -size / 2),
      child: SizedBox(width: _feedbackWidth, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jersey = jerseyImagePath;
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: scale,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (overSquadLimit)
                  Container(
                    width: size + 18,
                    height: size + 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withValues(alpha: 0.28),
                      border: Border.all(color: Colors.red.shade400, width: 2),
                    ),
                  ),
                SizedBox(
                  width: size,
                  height: size,
                  child: jersey != null
                      ? Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.amber
                                  : Colors.transparent,
                              width: 3.5,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(jersey, fit: BoxFit.contain),
                              Align(
                                alignment: const Alignment(0, 0.1),
                                child: _JerseyNumber(
                                  number: player.number,
                                  fontSize: size * 0.32,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade700,
                            border: Border.all(
                              color: isSelected ? Colors.amber : color,
                              width: isSelected ? 3.5 : 2.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${player.number}',
                            style: TextStyle(
                              fontSize: size * 0.4,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade200,
                            ),
                          ),
                        ),
                ),
                if (player.card == 'yellow2')
                  // A second yellow (implied red): two overlapping yellow
                  // cards instead of one, distinct from a plain single yellow.
                  Positioned(
                    top: -6,
                    left: -6,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: 4,
                            left: 4,
                            child: _CardChip(color: Colors.amber),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            child: _CardChip(color: Colors.amber),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (player.card != 'none')
                  Positioned(
                    top: -4,
                    left: -4,
                    child: _CardChip(
                      color: player.card == 'red'
                          ? Colors.red.shade600
                          : Colors.amber,
                    ),
                  ),
                if (player.isCaptain)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'C',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                if (player.substituted)
                  Positioned(
                    bottom: -4,
                    left: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.swap_horiz,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxWidth: 88),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(6),
              border: jersey != null
                  ? Border.all(
                      color: isSelected ? Colors.amber : color,
                      width: isSelected ? 2.5 : 1.5,
                    )
                  : null,
            ),
            child: Text(
              player.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single small card-shaped chip (yellow or red), used both for a plain
/// card and stacked (offset) to represent a second yellow.
class _CardChip extends StatelessWidget {
  const _CardChip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.white, width: 1),
      ),
    );
  }
}

/// A jersey-style number: white fill over a black stroke, so it reads
/// clearly regardless of the jersey artwork's own color underneath.
class _JerseyNumber extends StatelessWidget {
  const _JerseyNumber({required this.number, required this.fontSize});

  final int number;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final text = '$number';
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fontSize * 0.14
              ..color = Colors.black,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
