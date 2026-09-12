import 'package:flutter/material.dart';

import '../models/player.dart';
import '../state/tactics_controller.dart';

/// Standalone Oyuncular page - lets a coach build out and edit a squad's
/// roster (name, number, position, captain, lock) without opening the pitch
/// first. Reuses the same [TacticsController] the pitch screen edits, so
/// changes made here show up there immediately and vice versa.
class PlayersScreen extends StatelessWidget {
  const PlayersScreen({super.key, required this.controller});

  final TacticsController controller;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Ev Sahibi'),
                Tab(text: 'Deplasman'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _TeamRoster(controller: controller, team: 'home'),
                  _TeamRoster(controller: controller, team: 'away'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamRoster extends StatelessWidget {
  const _TeamRoster({required this.controller, required this.team});

  final TacticsController controller;
  final String team;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final players = controller.players.where((p) => p.team == team).toList()
          ..sort((a, b) => a.number.compareTo(b.number));
        final starters = players.where((p) => p.onPitch).toList();
        final bench = players.where((p) => !p.onPitch).toList();
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              if (starters.isNotEmpty) ...[
                _SectionHeader('Sahada (${starters.length})'),
                for (final player in starters)
                  _PlayerTile(controller: controller, player: player),
              ],
              if (bench.isNotEmpty) ...[
                _SectionHeader('Yedek (${bench.length})'),
                for (final player in bench)
                  _PlayerTile(controller: controller, player: player),
              ],
              if (players.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text('Bu takımda henüz oyuncu yok.')),
                ),
              const SizedBox(height: 80),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => controller.addPlayer(team),
            icon: const Icon(Icons.person_add),
            label: const Text('Oyuncu Ekle'),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(label, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.controller, required this.player});

  final TacticsController controller;
  final Player player;

  Future<void> _showEditDialog(BuildContext context) async {
    final nameController = TextEditingController(text: player.name);
    final numberController = TextEditingController(
      text: player.number.toString(),
    );
    final positionController = TextEditingController(text: player.position);
    final photoUrlController = TextEditingController(
      text: player.photoUrl ?? '',
    );
    final heightController = TextEditingController(
      text: player.heightCm?.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: player.weightKg?.toString() ?? '',
    );
    final birthYearController = TextEditingController(
      text: player.birthYear?.toString() ?? '',
    );
    final clubController = TextEditingController(text: player.club ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oyuncuyu düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'İsim'),
              ),
              TextField(
                controller: numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Forma numarası'),
              ),
              TextField(
                controller: positionController,
                decoration: const InputDecoration(
                  labelText: 'Mevki (ör. CB, ST)',
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 16, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Detay sayfası bilgileri (opsiyonel)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
              TextField(
                controller: photoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Fotoğraf URL (opsiyonel)',
                ),
              ),
              TextField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Boy (cm, opsiyonel)',
                ),
              ),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kilo (kg, opsiyonel)',
                ),
              ),
              TextField(
                controller: birthYearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Doğum yılı (opsiyonel)',
                ),
              ),
              TextField(
                controller: clubController,
                decoration: const InputDecoration(
                  labelText: 'Kulüp (opsiyonel)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    controller.renamePlayer(player.id, nameController.text);
    controller.setPlayerPosition(player.id, positionController.text);
    final number = int.tryParse(numberController.text);
    if (number != null) controller.setPlayerNumber(player.id, number);
    controller.updatePlayerBio(
      player.id,
      photoUrl: photoUrlController.text.trim().isEmpty
          ? null
          : photoUrlController.text.trim(),
      heightCm: int.tryParse(heightController.text),
      weightKg: int.tryParse(weightController.text),
      birthYear: int.tryParse(birthYearController.text),
      club: clubController.text.trim().isEmpty
          ? null
          : clubController.text.trim(),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oyuncuyu sil'),
        content: Text('${player.name} kadrodan tamamen silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed == true) controller.removePlayer(player.id);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text('${player.number}')),
        title: Text(player.name),
        subtitle: Text(player.position),
        onTap: () => _showEditDialog(context),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Kaptan',
              icon: Icon(
                player.isCaptain ? Icons.star : Icons.star_border,
                color: player.isCaptain ? Colors.amber : null,
              ),
              onPressed: () => controller.toggleCaptain(player.id),
            ),
            IconButton(
              tooltip: 'Kilitle',
              icon: Icon(player.locked ? Icons.lock : Icons.lock_open),
              onPressed: () => controller.toggleLock(player.id),
            ),
            IconButton(
              tooltip: 'Sil',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }
}
