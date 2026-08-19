import 'package:flutter/material.dart';

import '../models/player.dart';
import '../state/tactics_controller.dart';
import '../theme/app_colors.dart';
import 'player_piece.dart';

/// Which grouping of [team]'s roster the transfer list is currently
/// showing.
enum _TransferTab { starting11, first18, squad, bench, transfer }

/// The bench's right-side "transfer list": a small tabbed panel that lets
/// the coach browse [team]'s squad by group (İlk 11 / İlk 18 / Kadro /
/// Yedek) and drag/tap players onto the pitch, plus a "Transfer" tab to
/// register a brand-new player into the squad.
class TransferListPanel extends StatefulWidget {
  const TransferListPanel({
    super.key,
    required this.controller,
    required this.team,
    required this.selectedPlayerIds,
    required this.onSelectPlayer,
    required this.onDragEnd,
    required this.colorForPlayer,
    required this.onDoubleTapPlayer,
    this.jerseyImagePath,
  });

  final TacticsController controller;
  final String team;
  final Set<String> selectedPlayerIds;
  final ValueChanged<String> onSelectPlayer;
  final void Function(Player player, DraggableDetails details) onDragEnd;
  final Color Function(Player player) colorForPlayer;
  final ValueChanged<Player> onDoubleTapPlayer;
  final String? jerseyImagePath;

  @override
  State<TransferListPanel> createState() => _TransferListPanelState();
}

class _TransferListPanelState extends State<TransferListPanel> {
  _TransferTab _tab = _TransferTab.starting11;

  List<Player> _playersForTab(_TransferTab tab) {
    final teamPlayers = widget.controller.players
        .where((p) => p.team == widget.team)
        .toList();
    switch (tab) {
      case _TransferTab.starting11:
        return teamPlayers.where((p) => p.onPitch).toList();
      case _TransferTab.first18:
        return teamPlayers.take(18).toList();
      case _TransferTab.squad:
        return teamPlayers;
      case _TransferTab.bench:
        return teamPlayers.where((p) => !p.onPitch).toList();
      case _TransferTab.transfer:
        return const [];
    }
  }

  static const _tabLabels = {
    _TransferTab.starting11: 'İlk 11',
    _TransferTab.first18: 'İlk 18',
    _TransferTab.squad: 'Kadro',
    _TransferTab.bench: 'Yedek',
    _TransferTab.transfer: 'Transfer',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 210,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 26,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final entry in _tabLabels.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _TabChip(
                      label: entry.value,
                      selected: _tab == entry.key,
                      onTap: () => setState(() => _tab = entry.key),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _tab == _TransferTab.transfer
                ? _TransferTabBody(
                    onAddPlayer: () => widget.controller.addPlayer(widget.team),
                  )
                : _PlayerList(
                    players: _playersForTab(_tab),
                    selectedPlayerIds: widget.selectedPlayerIds,
                    onSelectPlayer: widget.onSelectPlayer,
                    onDragEnd: widget.onDragEnd,
                    colorForPlayer: widget.colorForPlayer,
                    onDoubleTapPlayer: widget.onDoubleTapPlayer,
                    jerseyImagePath: widget.jerseyImagePath,
                  ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.amber : Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.black : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _PlayerList extends StatelessWidget {
  const _PlayerList({
    required this.players,
    required this.selectedPlayerIds,
    required this.onSelectPlayer,
    required this.onDragEnd,
    required this.colorForPlayer,
    required this.onDoubleTapPlayer,
    this.jerseyImagePath,
  });

  final List<Player> players;
  final Set<String> selectedPlayerIds;
  final ValueChanged<String> onSelectPlayer;
  final void Function(Player player, DraggableDetails details) onDragEnd;
  final Color Function(Player player) colorForPlayer;
  final ValueChanged<Player> onDoubleTapPlayer;
  final String? jerseyImagePath;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return const Center(
        child: Text(
          'Bu listede oyuncu yok.',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );
    }
    return ListView.separated(
      itemCount: players.length,
      separatorBuilder: (context, i) =>
          const Divider(height: 1, color: Colors.white12),
      itemBuilder: (context, i) => _PlayerRow(
        player: players[i],
        selected: selectedPlayerIds.contains(players[i].id),
        color: colorForPlayer(players[i]),
        onTap: () => onSelectPlayer(players[i].id),
        onDoubleTap: () => onDoubleTapPlayer(players[i]),
        onDragEnd: (details) => onDragEnd(players[i], details),
        jerseyImagePath: jerseyImagePath,
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.selected,
    required this.color,
    required this.onTap,
    required this.onDoubleTap,
    required this.onDragEnd,
    this.jerseyImagePath,
  });

  final Player player;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final void Function(DraggableDetails details) onDragEnd;
  final String? jerseyImagePath;

  Widget _dot() => Container(
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.grey.shade700,
      border: Border.all(color: color, width: 1.5),
    ),
    child: Text(
      '${player.number}',
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final row = InkWell(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.amber.withValues(alpha: 0.15) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            _dot(),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                player.name,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.amber : Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              player.onPitch ? 'Sahada' : 'Yedek',
              style: TextStyle(
                fontSize: 10,
                color: player.onPitch ? Colors.greenAccent : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
    return Draggable<Player>(
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
      childWhenDragging: Opacity(opacity: 0.3, child: row),
      onDragEnd: onDragEnd,
      child: row,
    );
  }
}

class _TransferTabBody extends StatelessWidget {
  const _TransferTabBody({required this.onAddPlayer});

  final VoidCallback onAddPlayer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Kadroya yeni bir oyuncu ekleyin.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onAddPlayer,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amber,
              side: const BorderSide(color: Colors.amber),
            ),
            icon: const Icon(Icons.person_add_alt_1, size: 16),
            label: const Text('Oyuncu Ekle'),
          ),
        ],
      ),
    );
  }
}
