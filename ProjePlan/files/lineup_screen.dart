import 'package:flutter/material.dart';
import 'pitch_painter.dart';
import 'player_avatar.dart';
import 'player_model.dart';

/// Ekran görüntüsündeki gibi: üstte deplasman takımı, altta ev sahibi takım,
/// ortada top, en altta yatay kaydırmalı yedek kulübesi şeridi bulunan
/// tam bir kadro (lineup) ekranı.
class LineupScreen extends StatelessWidget {
  final List<PlayerModel> homeTeam; // Alt yarıdaki takım (siyah çerçeve gibi)
  final List<PlayerModel> awayTeam; // Üst yarıdaki takım (kırmızı çerçeve gibi)
  final List<PlayerModel> bench; // Yedek kulübesi
  final String matchTitle;

  const LineupScreen({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    this.bench = const [],
    this.matchTitle = 'Kadro',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(matchTitle),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: AspectRatio(
                aspectRatio: 3 / 4, // dikey saha oranı; yatay istersen 4/3 yap
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    return Stack(
                      children: [
                        // Saha zemini
                        Positioned.fill(
                          child: CustomPaint(painter: PitchPainter()),
                        ),
                        // Deplasman + ev sahibi oyuncular
                        for (final player in [...awayTeam, ...homeTeam])
                          Positioned(
                            left: player.x * w - 28,
                            top: player.y * h - 28,
                            child: PlayerAvatar(player: player),
                          ),
                        // Top, sahanın tam ortasında
                        Positioned(
                          left: w / 2 - 12,
                          top: h / 2 - 12,
                          child: const Icon(
                            Icons.sports_soccer,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          if (bench.isNotEmpty) _BenchStrip(bench: bench),
        ],
      ),
    );
  }
}

/// Alt kısımdaki yatay kaydırmalı "yedek kulübesi" şeridi.
class _BenchStrip extends StatelessWidget {
  final List<PlayerModel> bench;

  const _BenchStrip({required this.bench});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: bench.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final player = bench[index];
          return PlayerAvatar(player: player, avatarSize: 44);
        },
      ),
    );
  }
}
