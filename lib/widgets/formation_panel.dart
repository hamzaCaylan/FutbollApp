import 'package:flutter/material.dart';

import '../models/formation.dart';

/// Right-side sub-panel opened by the left rail's "Diziliş" button: lets the
/// coach pick the home team's formation without leaving the pitch.
class FormationPanel extends StatelessWidget {
  const FormationPanel({
    super.key,
    required this.current,
    required this.onSelect,
    this.compact = false,
  });

  final FormationType current;
  final ValueChanged<FormationType> onSelect;

  /// When true, renders as a narrow icon/label-only column that fits the
  /// left rail's width instead of the full labeled list.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact)
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              'Diziliş',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        for (final type in FormationType.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _FormationOption(
              type: type,
              selected: type == current,
              onTap: () => onSelect(type),
              compact: compact,
            ),
          ),
      ],
    );
  }
}

class _FormationOption extends StatelessWidget {
  const _FormationOption({
    required this.type,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final FormationType type;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      alignment: compact ? Alignment.center : Alignment.centerLeft,
      minimumSize: Size.fromHeight(compact ? 36 : 40),
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 2)
          : const EdgeInsets.symmetric(horizontal: 12),
      foregroundColor: selected ? Colors.black : Colors.white,
      backgroundColor: selected ? Colors.amber : null,
      side: BorderSide(color: selected ? Colors.amber : Colors.white24),
    );
    if (compact) {
      return Tooltip(
        message: type.label,
        child: OutlinedButton(
          onPressed: onTap,
          style: style,
          child: Text(
            type.label,
            style: const TextStyle(fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      style: style,
      icon: Icon(
        selected ? Icons.check_circle : Icons.circle_outlined,
        size: 16,
      ),
      label: Text(type.label, overflow: TextOverflow.ellipsis),
    );
  }
}
