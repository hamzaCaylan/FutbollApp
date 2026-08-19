import 'package:flutter/material.dart';

import '../models/player.dart';
import '../state/tactics_controller.dart';
import '../theme/app_colors.dart';
import 'player_piece.dart';
import 'transfer_list_panel.dart';

class Bench extends StatelessWidget {
  const Bench({
    super.key,
    required this.controller,
    required this.homePlayers,
    required this.awayPlayers,
    required this.selectedPlayerIds,
    required this.onSelectPlayer,
    required this.onDragEnd,
    required this.colorForPlayer,
    required this.onDoubleTapPlayer,
    this.jerseyImagePath,
  });

  /// Backs the right-side transfer list (İlk 11/İlk 18/Kadro/Yedek/Transfer
  /// tabs), which needs live access to the full roster rather than just the
  /// bench slice already passed in via [homePlayers]/[awayPlayers].
  final TacticsController controller;

  final List<Player> homePlayers;
  final List<Player> awayPlayers;
  final Set<String> selectedPlayerIds;
  final ValueChanged<String> onSelectPlayer;
  final void Function(Player player, DraggableDetails details) onDragEnd;
  final Color Function(Player player) colorForPlayer;
  final ValueChanged<Player> onDoubleTapPlayer;

  /// When set, bench avatars render this jersey artwork instead of the
  /// plain number-in-circle look; mirrors the pitch's Ayarlar setting.
  final String? jerseyImagePath;

  Widget _avatar(Player player) {
    final color = colorForPlayer(player);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Draggable<Player>(
        data: player,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: PlayerPiece.centeredFeedback(
          child: Opacity(
            opacity: 0.85,
            child: PlayerPiece(
              player: player,
              isSelected: false,
              onTap: () {},
              color: color,
              jerseyImagePath: jerseyImagePath,
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
          ),
        ),
        onDragEnd: (details) => onDragEnd(player, details),
        child: PlayerPiece(
          player: player,
          isSelected: selectedPlayerIds.contains(player.id),
          onTap: () => onSelectPlayer(player.id),
          onDoubleTap: () => onDoubleTapPlayer(player),
          color: color,
          jerseyImagePath: jerseyImagePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelDark,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Yedekler',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 84,
                  child: Row(
                    children: [
                      // Home substitutes anchor toward the pitch's left half.
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final player in homePlayers) _avatar(player),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 1, height: 60, color: Colors.white24),
                      // Away substitutes anchor toward the pitch's right half.
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            child: Row(
                              children: [
                                for (final player in awayPlayers)
                                  _avatar(player),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Oyuncuyu sürükleyerek veya üzerine tıklayarak sahaya ekleyebilirsiniz.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                    const _LegendDot(color: AppColors.teamHomeDefault),
                    const SizedBox(width: 4),
                    Text(
                      'Başlangıç',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _LegendDot(color: Colors.red.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Yedek',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TransferListPanel(
            controller: controller,
            team: 'home',
            selectedPlayerIds: selectedPlayerIds,
            onSelectPlayer: onSelectPlayer,
            onDragEnd: onDragEnd,
            colorForPlayer: colorForPlayer,
            onDoubleTapPlayer: onDoubleTapPlayer,
            jerseyImagePath: jerseyImagePath,
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white38),
      ),
    );
  }
}
