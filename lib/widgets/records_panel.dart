import 'package:flutter/material.dart';

import '../models/tactic.dart';
import '../state/tactics_controller.dart';

/// Left rail's "Kayıtlar" sub-panel: every saved tactic/plan (each a named
/// board snapshot the coach can bookmark and switch back to), matching the
/// same docked-panel convention as Diziliş/Taktikler/Araçlar.
class RecordsPanel extends StatelessWidget {
  const RecordsPanel({
    super.key,
    required this.controller,
    required this.onSaveAsNew,
    required this.onRename,
    required this.onInfo,
    this.compact = false,
  });

  final TacticsController controller;

  /// Prompts for a name and saves the current live board as a new entry.
  final VoidCallback onSaveAsNew;

  /// Prompts for a new name for the tactic with this id/current name.
  final void Function(String id, String currentName) onRename;

  /// Opens the info dialog (title + description + category) for the tactic
  /// with this id/current name/current description/current category.
  final void Function(
    String id,
    String currentName,
    String currentDescription,
    String currentCategory,
  )
  onInfo;

  /// When true, renders as a narrow icon-only column that fits the left
  /// rail's width instead of the full labeled list.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact)
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Kayıtlar',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        if (compact)
          Tooltip(
            message: 'Yeni Kayıt',
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onSaveAsNew,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber,
                  side: const BorderSide(color: Colors.amber),
                ),
                child: const Icon(Icons.add, size: 18),
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSaveAsNew,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amber,
                side: const BorderSide(color: Colors.amber),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Yeni Kayıt'),
            ),
          ),
        const SizedBox(height: 10),
        for (final tactic in controller.tactics)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _RecordTile(
              tactic: tactic,
              selected: tactic.id == controller.currentTacticId,
              compact: compact,
              onTap: () => controller.switchTactic(tactic.id),
              onRename: () => onRename(tactic.id, tactic.name),
              onInfo: () => onInfo(
                tactic.id,
                tactic.name,
                tactic.description,
                tactic.category,
              ),
              onDelete: controller.tactics.length > 1
                  ? () => controller.deleteTactic(tactic.id)
                  : null,
            ),
          ),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.tactic,
    required this.selected,
    required this.compact,
    required this.onTap,
    required this.onRename,
    required this.onInfo,
    required this.onDelete,
  });

  final Tactic tactic;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onInfo;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Tooltip(
        message: tactic.name,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: selected ? Colors.black : Colors.white,
              backgroundColor: selected ? Colors.amber : null,
              side: BorderSide(color: selected ? Colors.amber : Colors.white24),
            ),
            child: const Icon(Icons.bookmark_outline, size: 18),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: selected ? Colors.amber.withValues(alpha: 0.15) : null,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? Colors.amber : Colors.white24),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Text(
                  tactic.name,
                  style: TextStyle(
                    color: selected ? Colors.amber : Colors.white,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 16),
            color: Colors.grey.shade400,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onInfo,
            tooltip: 'Bilgi',
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            color: Colors.grey.shade400,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onRename,
            tooltip: 'Yeniden adlandır',
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16),
              color: Colors.grey.shade400,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onDelete,
              tooltip: 'Sil',
            ),
        ],
      ),
    );
  }
}
