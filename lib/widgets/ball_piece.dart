import 'package:flutter/material.dart';

class BallPiece extends StatelessWidget {
  const BallPiece({super.key, required this.onTap, this.imagePath});

  final VoidCallback onTap;

  /// When set, renders this artwork instead of the plain sports_soccer
  /// icon. Chosen from the Ayarlar dialog.
  final String? imagePath;

  static const double size = 32;

  /// Wraps drag feedback so the ball is centered under the pointer instead
  /// of `pointerDragAnchorStrategy`'s default of pinning the widget's
  /// top-left corner to the cursor.
  static Widget centeredFeedback({required Widget child}) {
    return Transform.translate(
      offset: const Offset(-size / 2, -size / 2),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: path != null
            ? ClipOval(
                child: Image.asset(
                  path,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                ),
              )
            : const Icon(
                Icons.sports_soccer,
                size: 26,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
      ),
    );
  }
}
