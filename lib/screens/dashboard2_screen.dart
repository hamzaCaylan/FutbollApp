import 'package:flutter/material.dart';

import '../models/app_page.dart';
import '../models/formation.dart';
import '../models/player.dart';
import '../state/tactics_controller.dart';
import '../theme/app_colors.dart';

/// A second dashboard styled as a light, editorial "player profile" page
/// (team nav bar, big cutout jersey, red number/position callouts, quick
/// facts either side, and a scoreboard-style summary card) instead of the
/// first dashboard's dark cinematic streaming look.
class Dashboard2Screen extends StatelessWidget {
  const Dashboard2Screen({
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
        final homePlayers = controller.players
            .where((p) => p.team == 'home')
            .toList();
        if (homePlayers.isEmpty) {
          return const ColoredBox(color: AppColors.offWhite);
        }
        final featured = homePlayers.firstWhere(
          (p) => p.isCaptain,
          orElse: () => homePlayers.firstWhere(
            (p) => p.onPitch,
            orElse: () => homePlayers.first,
          ),
        );
        final pitchCount = controller.pitchPlayers
            .where((p) => p.team == 'home')
            .length;
        final benchCount = controller.benchPlayers('home').length;
        final currentTactic = controller.tactics.firstWhere(
          (t) => t.id == controller.currentTacticId,
          orElse: () => controller.tactics.first,
        );

        return Container(
          color: const Color(0xFFE7E8EC),
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 900;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.charcoal,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(6),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          _TopNav(compact: compact, onSelectPage: onSelectPage),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                28,
                                20,
                                28,
                                28,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  compact
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _LeftInfo(player: featured),
                                            const SizedBox(height: 16),
                                            _HeroPhoto(
                                              controller: controller,
                                              player: featured,
                                              tacticName: currentTactic.name,
                                              height: 320,
                                            ),
                                            const SizedBox(height: 16),
                                            _SummaryCard(
                                              controller: controller,
                                              pitchCount: pitchCount,
                                              benchCount: benchCount,
                                            ),
                                          ],
                                        )
                                      : IntrinsicHeight(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                width: 220,
                                                child: _LeftInfo(
                                                  player: featured,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: _HeroPhoto(
                                                  controller: controller,
                                                  player: featured,
                                                  tacticName:
                                                      currentTactic.name,
                                                  height: 420,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              SizedBox(
                                                width: 240,
                                                child: _SummaryCard(
                                                  controller: controller,
                                                  pitchCount: pitchCount,
                                                  benchCount: benchCount,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  const SizedBox(height: 20),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    children: [
                                      _StatChip(
                                        label: 'SAHADAKİ OYUNCU',
                                        value: '$pitchCount',
                                      ),
                                      _StatChip(
                                        label: 'YEDEK OYUNCU',
                                        value: '$benchCount',
                                      ),
                                      _StatChip(
                                        label: 'KAYITLI PLAN',
                                        value: '${controller.tactics.length}',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _FactColumn(
                                          facts: [
                                            ('FORMA NO', '#${featured.number}'),
                                            (
                                              'DURUM',
                                              featured.onPitch
                                                  ? 'Sahada'
                                                  : 'Yedek',
                                            ),
                                            (
                                              'TAKIM',
                                              featured.team == 'home'
                                                  ? 'Ev Sahibi'
                                                  : 'Deplasman',
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: _FactColumn(
                                          alignEnd: true,
                                          facts: [
                                            ('PLAN ADI', currentTactic.name),
                                            (
                                              'DİZİLİŞ',
                                              controller.homeFormation.label,
                                            ),
                                            (
                                              'OYUNCU SAYISI',
                                              '${homePlayers.length}',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav({required this.compact, required this.onSelectPage});

  final bool compact;
  final ValueChanged<AppPage> onSelectPage;

  static const _links = [
    (label: 'DİZİLİŞ', page: AppPage.pitch),
    (label: 'OYUNCULAR', page: AppPage.players),
    (label: 'AYARLAR', page: AppPage.settings),
    (label: 'KILAVUZ', page: AppPage.help),
    (label: 'DASHBOARD', page: AppPage.dashboard),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDEDED))),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_soccer,
              size: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'FC MANAGER',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.5,
              color: AppColors.charcoal,
            ),
          ),
          const Spacer(),
          if (compact)
            PopupMenuButton<AppPage>(
              icon: const Icon(Icons.menu, color: Colors.black54),
              onSelected: onSelectPage,
              itemBuilder: (context) => [
                for (final link in _links)
                  PopupMenuItem(value: link.page, child: Text(link.label)),
              ],
            )
          else
            Wrap(
              spacing: 24,
              children: [
                for (final link in _links)
                  InkWell(
                    onTap: () => onSelectPage(link.page),
                    child: Text(
                      link.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(width: 24),
          InkWell(
            onTap: () => onSelectPage(AppPage.settings),
            customBorder: const CircleBorder(),
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.taupe,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeftInfo extends StatelessWidget {
  const _LeftInfo({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E2E2)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(width: 6),
              Icon(Icons.star_border, size: 14, color: Colors.black54),
              SizedBox(width: 4),
              Padding(
                padding: EdgeInsets.only(right: 4),
                child: Text(
                  'Aktif Plan',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          player.name,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.charcoal,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.charcoal,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield, size: 10, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              player.team == 'home' ? 'Ev Sahibi Kadro' : 'Deplasman Kadro',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            _MiniStat(label: 'FORMA', value: '#${player.number}'),
            const SizedBox(width: 28),
            _MiniStat(label: 'MEVKİ', value: player.position),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black45,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
      ],
    );
  }
}

class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto({
    required this.controller,
    required this.player,
    required this.tacticName,
    required this.height,
  });

  final TacticsController controller;
  final Player player;
  final String tacticName;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Text(
            tacticName.toUpperCase(),
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Colors.black.withValues(alpha: 0.05),
              height: 1,
            ),
          ),
          Positioned(
            left: 0,
            child: Text(
              '#${player.number}',
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: AppColors.red,
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 8,
            child: Text(
              player.position,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.red,
              ),
            ),
          ),
          if (controller.jerseyImage != null)
            Image.asset(
              controller.jerseyImage!,
              height: height,
              fit: BoxFit.contain,
            )
          else
            Icon(Icons.person, size: height * 0.6, color: Colors.black26),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.controller,
    required this.pitchCount,
    required this.benchCount,
  });

  final TacticsController controller;
  final int pitchCount;
  final int benchCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEDEDED)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KADRO ÖZETİ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.black45,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$pitchCount',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const Text(
                          'Sahada',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: const Color(0xFFE2E2E2),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$benchCount',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const Text(
                          'Yedek',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _Thumb(imagePath: 'assets/dashboard/dash1.png')),
            const SizedBox(width: 10),
            Expanded(child: _Thumb(imagePath: 'assets/dashboard/top2.jpg')),
          ],
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(imagePath, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(color: Colors.black26),
            ),
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white60,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_upward, size: 14, color: AppColors.red),
            ],
          ),
        ],
      ),
    );
  }
}

class _FactColumn extends StatelessWidget {
  const _FactColumn({required this.facts, this.alignEnd = false});

  final List<(String, String)> facts;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        for (final fact in facts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (alignEnd) ...[
                  Text(
                    fact.$2,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
                SizedBox(
                  width: 110,
                  child: Text(
                    fact.$1,
                    textAlign: alignEnd ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black45,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                if (!alignEnd) ...[
                  const SizedBox(width: 24),
                  Text(
                    fact.$2,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
