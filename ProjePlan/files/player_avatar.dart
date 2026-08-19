import 'package:flutter/material.dart';
import 'player_model.dart';

/// Sahadaki tek bir oyuncuyu (fotoğraf + numara rozeti + isim etiketi) çizen widget.
/// Sürükle-bırak istersen bunu [Draggable] ile sarmalayabilirsin (aşağıda örnek var).
class PlayerAvatar extends StatelessWidget {
  final PlayerModel player;
  final double avatarSize;
  final VoidCallback? onTap;

  const PlayerAvatar({
    super.key,
    required this.player,
    this.avatarSize = 56,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: player.teamColor, width: 2.5),
                  color: Colors.grey.shade800,
                ),
                child: ClipOval(
                  child: player.photoUrl != null
                      ? Image.network(
                          player.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initialsFallback(),
                        )
                      : _initialsFallback(),
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
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${player.number} ${player.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsFallback() {
    return Center(
      child: Text(
        player.number.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
