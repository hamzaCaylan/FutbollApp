import 'package:flutter/material.dart';

import '../models/app_page.dart';
import '../models/tactic.dart';
import '../state/tactics_controller.dart';

/// Standalone "Kayıtlar" page reachable from the sidebar: every saved
/// [Tactic] (created via the pitch editor's Kayıtlar panel or "Yeni Plan"),
/// grouped into Maçlar/Taktikler/Goller/Aksiyonlar cards by its free-text
/// [Tactic.category] - so a coach can browse everything they've saved
/// without first opening the pitch editor. Tapping a record switches to it
/// and opens the pitch editor on it, same as the in-editor Kayıtlar panel.
class RecordsScreen extends StatelessWidget {
  const RecordsScreen({
    super.key,
    required this.controller,
    required this.onSelectPage,
  });

  final TacticsController controller;
  final ValueChanged<AppPage> onSelectPage;

  static const _groups = [
    _RecordGroup('Maçlar', Icons.sports_soccer, ['maç', 'mac']),
    _RecordGroup('Taktikler', Icons.hub_outlined, ['taktik']),
    _RecordGroup('Goller', Icons.sports_score, ['gol']),
    _RecordGroup('Aksiyonlar', Icons.bolt_outlined, ['aksiyon']),
  ];

  _RecordGroup? _matchGroup(String category) {
    for (final group in _groups) {
      for (final keyword in group.keywords) {
        if (category.contains(keyword)) return group;
      }
    }
    return null;
  }

  void _openRecord(Tactic tactic) {
    controller.switchTactic(tactic.id);
    onSelectPage(AppPage.pitch);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final grouped = <_RecordGroup, List<Tactic>>{
          for (final group in _groups) group: [],
        };
        final other = <Tactic>[];
        for (final tactic in controller.tactics) {
          final match = _matchGroup(tactic.category.trim().toLowerCase());
          if (match != null) {
            grouped[match]!.add(tactic);
          } else {
            other.add(tactic);
          }
        }
        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Kayıtlar',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Kaydedilen maç, taktik, gol ve aksiyonlar kategorilerine göre burada listelenir.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              for (final group in _groups)
                _GroupCard(
                  group: group,
                  tactics: grouped[group]!,
                  onOpen: _openRecord,
                ),
              if (other.isNotEmpty)
                _GroupCard(
                  group: const _RecordGroup('Diğer', Icons.folder_outlined, []),
                  tactics: other,
                  onOpen: _openRecord,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RecordGroup {
  const _RecordGroup(this.title, this.icon, this.keywords);

  final String title;
  final IconData icon;
  final List<String> keywords;
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.tactics,
    required this.onOpen,
  });

  final _RecordGroup group;
  final List<Tactic> tactics;
  final ValueChanged<Tactic> onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(group.icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  group.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tactics.length}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (tactics.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Bu grupta henüz kayıt yok.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              )
            else
              for (final tactic in tactics)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: Text(tactic.name),
                  subtitle: tactic.description.trim().isEmpty
                      ? null
                      : Text(
                          tactic.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onOpen(tactic),
                ),
          ],
        ),
      ),
    );
  }
}
