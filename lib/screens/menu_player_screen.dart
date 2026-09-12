import 'package:flutter/material.dart';

import '../models/app_page.dart';
import '../state/tactics_controller.dart';

/// "MenuPlayer" page reachable from the sidebar: a grid of player cards -
/// tapping one navigates to the player detail page. Card design/content is
/// a placeholder (avatar, name, number, position) until the final look is
/// specified.
class MenuPlayerScreen extends StatelessWidget {
  const MenuPlayerScreen({
    super.key,
    required this.controller,
    required this.onSelectPage,
  });

  final TacticsController controller;
  final ValueChanged<AppPage> onSelectPage;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final players =
            controller.players.where((p) => p.team == 'home').toList()
              ..sort((a, b) => a.number.compareTo(b.number));
        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MenuPlayer',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Bir oyuncu kartına tıklayınca detay sayfası açılır.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: players.isEmpty
                      ? const Center(child: Text('Henüz oyuncu yok.'))
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 160,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: players.length,
                          itemBuilder: (context, index) {
                            final player = players[index];
                            return _PlayerCard(
                              name: player.name,
                              number: player.number,
                              position: player.position,
                              isCaptain: player.isCaptain,
                              onTap: () {
                                controller.viewPlayerDetail(player.id);
                                onSelectPage(AppPage.dash1);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.name,
    required this.number,
    required this.position,
    required this.isCaptain,
    required this.onTap,
  });

  final String name;
  final int number;
  final String position;
  final bool isCaptain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(position, style: Theme.of(context).textTheme.bodySmall),
              if (isCaptain) ...[
                const SizedBox(height: 4),
                const Icon(Icons.star, size: 14, color: Colors.amber),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
