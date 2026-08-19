import 'package:flutter/material.dart';

import '../models/app_page.dart';
import '../theme/app_colors.dart';

/// A high-fidelity build-out of the layered "player profile" hero dashboard
/// described in assets/not/prdash.md, populated with Dušan Vlahović's
/// Beşiktaş transfer profile: watermark typography behind a floating
/// cutout, side info panels, a match/media column, and three gradient
/// stat cards overlapping the hero's lower edge.
class Dash1Screen extends StatelessWidget {
  const Dash1Screen({super.key, required this.onSelectPage});

  final ValueChanged<AppPage> onSelectPage;

  static const _navy = Color(0xFF0D2240);
  static const _bg = Color(0xFFF4F5F8);
  static const _watermark = Color(0xFFE5E8ED);
  static const _heroImage = 'assets/dashboard/v3.png';

  // --- Vlahović / Beşiktaş profile data ---------------------------------
  static const _watermarkText = 'BESIKTAS';
  static const _heroNumber = '#28';
  static const _heroPosition = 'ST';
  static const _playerName = 'Dušan Vlahović';
  static const _clubName = 'Beşiktaş JK';
  static const _height = '1.90 m';
  static const _weight = '75 kg';
  static const _born = '28/01/2000';
  static const _age = '26';
  static const _origin = 'Belgrad, Sırbistan';
  static const _debut = '2016 (Partizan)';
  static const _previousClubs = ['JUV 2022-26', 'FIO 2018-22', 'PAR 2016-18'];
  static const _homeTeam = 'Beşiktaş';
  static const _awayTeam = 'Galatasaray';
  static const _matchScore = '2 - 1';
  static const _league = 'SÜPER LİG';
  static const _matchStatus = 'FINAL';
  static const _statCards = [
    ('MAÇ BAŞI GOL', '0.55'),
    ('İSABETLİ ŞUT', '1.8'),
    ('GOL ÇEVİRME ORANI', '21%'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1000;
          final body = compact
              ? _CompactBody(onSelectPage: onSelectPage)
              : _WideBody(onSelectPage: onSelectPage);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [const _SideRail(), Expanded(child: body)],
          );
        },
      ),
    );
  }
}

/// The ultra-narrow dark-navy rail from the reference layout's left edge.
class _SideRail extends StatelessWidget {
  const _SideRail();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      color: Dash1Screen._navy,
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 22),
      child: const Icon(Icons.menu, color: Colors.white70, size: 18),
    );
  }
}

class _WideBody extends StatelessWidget {
  const _WideBody({required this.onSelectPage});

  final ValueChanged<AppPage> onSelectPage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopNav(compact: false, onSelectPage: onSelectPage),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(
                child: _Hero(leftInset: 348, rightInset: 436),
              ),
              const Positioned(
                left: 32,
                bottom: 220,
                width: 300,
                child: _LeftPanel(),
              ),
              const Positioned(
                right: 32,
                top: 100,
                width: 380,
                child: _RightPanel(),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 28,
                child: FractionallySizedBox(
                  widthFactor: 0.75,
                  child: Row(
                    children: [
                      for (var i = 0; i < Dash1Screen._statCards.length; i++) ...[
                        if (i != 0) const SizedBox(width: 14),
                        Expanded(
                          child: _GradientStatCard(
                            label: Dash1Screen._statCards[i].$1,
                            value: Dash1Screen._statCards[i].$2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactBody extends StatelessWidget {
  const _CompactBody({required this.onSelectPage});

  final ValueChanged<AppPage> onSelectPage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopNav(compact: true, onSelectPage: onSelectPage),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 260, child: _Hero()),
                const SizedBox(height: 20),
                const _LeftPanel(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    for (
                      var i = 0;
                      i < Dash1Screen._statCards.length;
                      i++
                    ) ...[
                      if (i != 0) const SizedBox(width: 12),
                      Expanded(
                        child: _GradientStatCard(
                          label: Dash1Screen._statCards[i].$1,
                          value: Dash1Screen._statCards[i].$2,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                const _MatchCard(),
                const SizedBox(height: 16),
                const _VideoCarousel(),
                const SizedBox(height: 16),
                const _CareerSummary(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Top navigation bar: brand mark, section links (only "OYUNCULAR" routes
/// anywhere real - the rest mirror the reference nav's breadth), and an
/// avatar with a dropdown caret.
class _TopNav extends StatelessWidget {
  const _TopNav({required this.compact, required this.onSelectPage});

  final bool compact;
  final ValueChanged<AppPage> onSelectPage;

  static const _links = [
    'SKORLAR',
    'FİKSTÜR',
    'HABERLER',
    'İSTATİSTİK',
    'OYUNCULAR',
    'TAKIMLAR',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: Colors.black54),
              onSelected: (label) {
                if (label == 'OYUNCULAR') onSelectPage(AppPage.players);
              },
              itemBuilder: (context) => [
                for (final link in _links)
                  PopupMenuItem(value: link, child: Text(link)),
              ],
            )
          else
            Wrap(
              spacing: 22,
              children: [
                for (final link in _links)
                  InkWell(
                    onTap: link == 'OYUNCULAR'
                        ? () => onSelectPage(AppPage.players)
                        : null,
                    child: Text(
                      link,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: link == 'OYUNCULAR'
                            ? AppColors.charcoal
                            : Colors.black45,
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
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.taupe,
                  child: Icon(Icons.person, size: 16, color: Colors.white),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Colors.black45,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The hero area: giant faint watermark typography, a thin circular vector
/// outline, oversized red number/position callouts, and the floating
/// cutout overlapping the bottom edge.
class _Hero extends StatelessWidget {
  const _Hero({this.leftInset = 44, this.rightInset = 44});

  /// Horizontal clearance for the oversized number/position callouts, so
  /// they don't wash out overlapping side panels in the wide layout.
  final double leftInset;
  final double rightInset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return ClipRect(
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        Dash1Screen._watermarkText,
                        style: const TextStyle(
                          fontFamily: 'Anton',
                          fontSize: 190,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -4,
                          color: Dash1Screen._watermark,
                          height: 0.95,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: h * 0.82,
                height: h * 0.82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                ),
              ),
              Positioned(
                left: leftInset,
                top: h * 0.10,
                child: Text(
                  Dash1Screen._heroNumber,
                  style: TextStyle(
                    fontSize: h * 0.18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.red.withValues(alpha: 0.88),
                    height: 1,
                  ),
                ),
              ),
              Positioned(
                right: rightInset,
                top: h * 0.08,
                child: Text(
                  Dash1Screen._heroPosition,
                  style: TextStyle(
                    fontSize: h * 0.14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.red.withValues(alpha: 0.8),
                    height: 1,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Image.asset(
                  Dash1Screen._heroImage,
                  height: h * 0.84,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Left info panel: favorite pill, name + club, height/weight grid, and a
/// divided key-value table (born / age / origin).
class _LeftPanel extends StatelessWidget {
  const _LeftPanel();

  static const _ink = Color(0xFF12141A);
  static const _accentBlue = Color(0xFF1D4ED8);
  static const _dividerColor = Color(0xFFE3E5EA);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: _accentBlue, width: 1.4),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_border, size: 18, color: _accentBlue),
              SizedBox(width: 8),
              Text(
                'FAVORİ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _accentBlue,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                Dash1Screen._playerName,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  height: 0.98,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 10),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 28,
                color: _ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.charcoal,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                Dash1Screen._clubName,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                  color: _ink,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(height: 1, color: _dividerColor),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                child: _SpecTile(label: 'BOY', value: Dash1Screen._height),
              ),
              const SizedBox(width: 24),
              Container(width: 1, color: _dividerColor),
              const SizedBox(width: 24),
              const Expanded(
                child: _SpecTile(label: 'KİLO', value: Dash1Screen._weight),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(height: 1, color: _dividerColor),
        const _InfoRow(label: 'DOĞUM', value: Dash1Screen._born),
        const _InfoRow(label: 'YAŞ', value: Dash1Screen._age),
        const _InfoRow(label: 'MENŞEİ', value: Dash1Screen._origin, isLast: true),
      ],
    );
  }
}

class _SpecTile extends StatelessWidget {
  const _SpecTile({required this.label, required this.value});

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
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black45,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _LeftPanel._ink,
          ),
        ),
      ],
    );
  }
}

/// A label/value table row styled like a two-column NBA.com fact table:
/// a fixed-width label column on the left, the value left-aligned in the
/// remaining space, with a divider rule below.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black45,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _LeftPanel._ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Container(height: 1, color: _LeftPanel._dividerColor),
      ],
    );
  }
}

/// Right column: match score card, video highlight carousel, and a career
/// summary block - the reference's "Matches & Media" panel.
class _RightPanel extends StatelessWidget {
  const _RightPanel();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MatchCard(),
        SizedBox(height: 16),
        _VideoCarousel(),
        SizedBox(height: 16),
        _CareerSummary(),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'SON MAÇ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.charcoal,
                ),
              ),
              SizedBox(width: 22),
              Text(
                'SONRAKİ MAÇ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            Dash1Screen._league,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black38,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: _TeamScoreBlock(label: Dash1Screen._homeTeam),
              ),
              Column(
                children: [
                  const Text(
                    Dash1Screen._matchScore,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEFEF),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      Dash1Screen._matchStatus,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Flexible(
                child: _TeamScoreBlock(label: Dash1Screen._awayTeam),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamScoreBlock extends StatelessWidget {
  const _TeamScoreBlock({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.charcoal,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shield, size: 18, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.charcoal,
          ),
        ),
      ],
    );
  }
}

/// Horizontal highlight-clip carousel with a play-icon overlay and a
/// duration badge on each thumbnail, per the reference layout.
class _VideoCarousel extends StatelessWidget {
  const _VideoCarousel();

  static const _clips = [
    (
      image: 'assets/dashboard/ds.jpg',
      duration: '1:15',
      title: 'Antrenman Öne Çıkanları',
    ),
    (image: 'assets/dashboard/es.jpg', duration: '0:48', title: 'Gol Anları'),
    (
      image: 'assets/dashboard/top1.jpg',
      duration: '2:03',
      title: 'Taktik Analiz',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 158,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _clips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final clip = _clips[index];
          return SizedBox(
            width: 128,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(clip.image, fit: BoxFit.cover),
                        Container(
                          color: Colors.black.withValues(alpha: 0.18),
                        ),
                        const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              clip.duration,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  clip.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Career summary: pro debut and a short list of previous clubs, per the
/// reference's "NBA DEBUT / YEARS IN NBA / PREVIOUSLY" block.
class _CareerSummary extends StatelessWidget {
  const _CareerSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KARİYER ÖZETİ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black45,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROFESYONEL DEBÜT',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  Dash1Screen._debut,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'ÖNCEKİ TAKIMLAR',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black45,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          for (final club in Dash1Screen._previousClubs)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    club,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One of the three dark royal-blue gradient cards floating over the
/// hero's lower edge.
class _GradientStatCard extends StatelessWidget {
  const _GradientStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3B8E), Color(0xFF0A2968)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2968).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _TrendLinePainter())),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3E7BFA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Faint ascending zigzag trend line decorating the lower-right corner of
/// [_GradientStatCard], echoing a stock-chart sparkline.
class _TrendLinePainter extends CustomPainter {
  const _TrendLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6FA8FF).withValues(alpha: 0.3)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final points = [
      Offset(size.width * 0.44, size.height * 0.95),
      Offset(size.width * 0.56, size.height * 0.80),
      Offset(size.width * 0.50, size.height * 0.66),
      Offset(size.width * 0.66, size.height * 0.58),
      Offset(size.width * 0.60, size.height * 0.42),
      Offset(size.width * 0.80, size.height * 0.30),
      Offset(size.width * 0.72, size.height * 0.16),
      Offset(size.width * 1.02, size.height * 0.02),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) => false;
}
