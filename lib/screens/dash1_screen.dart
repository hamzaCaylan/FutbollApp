import 'package:flutter/material.dart';

import '../models/app_page.dart';
import '../models/player_profile.dart';
import '../state/tactics_controller.dart';
import '../theme/app_colors.dart';

/// A high-fidelity build-out of the layered "player profile" hero dashboard
/// described in assets/not/prdash.md, now driven by a real roster player
/// instead of the original static demo JSON: watermark typography behind a
/// floating cutout, a left info panel, and three gradient stat cards
/// overlapping the hero's lower edge. Reached from MenuPlayerScreen (which
/// sets [TacticsController.viewingPlayerId] before navigating here) or
/// directly from the sidebar, in which case it falls back to the roster's
/// first home player.
class Dash1Screen extends StatelessWidget {
  const Dash1Screen({
    super.key,
    required this.controller,
    required this.onSelectPage,
  });

  final TacticsController controller;
  final ValueChanged<AppPage> onSelectPage;

  static const _navy = Color(0xFF0D2240);
  static const _bg = Color(0xFFF4F5F8);
  static const _watermark = Color(0xFFE5E8ED);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final homePlayers =
            controller.players.where((p) => p.team == 'home').toList()
              ..sort((a, b) => a.number.compareTo(b.number));
        final viewingId = controller.viewingPlayerId;
        final player = homePlayers.where((p) => p.id == viewingId).firstOrNull;
        final resolved = player ?? homePlayers.firstOrNull;
        final profile = resolved != null
            ? PlayerProfile.fromPlayer(resolved, controller: controller)
            : null;
        // Inter is this screen's default text face (nav, labels, buttons,
        // body copy); Anton is applied explicitly on the decorative
        // headline elements - watermark, hero number/position, player
        // name, stat values.
        return DefaultTextStyle.merge(
          style: const TextStyle(fontFamily: 'Inter'),
          child: Container(
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
            child: profile == null
                ? const Center(child: Text('Kadroda henüz oyuncu yok.'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 1000;
                      final body = compact
                          ? _CompactBody(
                              profile: profile,
                              onSelectPage: onSelectPage,
                            )
                          : _WideBody(
                              profile: profile,
                              onSelectPage: onSelectPage,
                            );
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _SideRail(),
                          Expanded(child: body),
                        ],
                      );
                    },
                  ),
          ),
        );
      },
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
  const _WideBody({required this.profile, required this.onSelectPage});

  final PlayerProfile profile;
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
              Positioned.fill(
                child: _Hero(profile: profile, leftInset: 348, rightInset: 436),
              ),
              Positioned(
                left: 32,
                bottom: 220,
                width: 300,
                child: _LeftPanel(profile: profile),
              ),
              Positioned(
                right: 32,
                top: 100,
                width: 380,
                child: _TeamPanel(profile: profile),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 28,
                child: FractionallySizedBox(
                  widthFactor: 0.75,
                  child: Row(
                    children: [
                      for (var i = 0; i < profile.stats.length; i++) ...[
                        if (i != 0) const SizedBox(width: 14),
                        Expanded(
                          child: _GradientStatCard(
                            label: profile.stats[i].label,
                            value: profile.stats[i].value,
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
  const _CompactBody({required this.profile, required this.onSelectPage});

  final PlayerProfile profile;
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
                SizedBox(height: 260, child: _Hero(profile: profile)),
                const SizedBox(height: 20),
                _LeftPanel(profile: profile),
                const SizedBox(height: 20),
                Row(
                  children: [
                    for (var i = 0; i < profile.stats.length; i++) ...[
                      if (i != 0) const SizedBox(width: 12),
                      Expanded(
                        child: _GradientStatCard(
                          label: profile.stats[i].label,
                          value: profile.stats[i].value,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                _TeamPanel(profile: profile),
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
  const _Hero({
    required this.profile,
    this.leftInset = 44,
    this.rightInset = 44,
  });

  final PlayerProfile profile;

  /// Shown whenever a player has no photoUrl set (or it fails to load) -
  /// a generic cutout jersey photo, matching the reference layout's look,
  /// instead of a bare "person" icon.
  static const _defaultHeroImage = 'assets/dashboard/v3.png';

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
                top: 16,
                left: 36,
                right: 0,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Colors.transparent],
                          stops: [0.35, 1.0],
                        ).createShader(bounds),
                        blendMode: BlendMode.dstIn,
                        child: Text(
                          profile.watermarkText,
                          style: const TextStyle(
                            fontFamily: 'Anton',
                            fontSize: 360,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                            color: Dash1Screen._watermark,
                            height: 0.95,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: h * 0.74 + 18,
                height: h * 0.74 + 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFBDBDBD),
                    width: 1.2,
                  ),
                ),
              ),
              Positioned(
                left: leftInset,
                top: h * 0.10,
                child: Text(
                  profile.heroNumber,
                  style: TextStyle(
                    fontFamily: 'Anton',
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
                  profile.heroPosition,
                  style: TextStyle(
                    fontFamily: 'Anton',
                    fontSize: h * 0.14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.red.withValues(alpha: 0.8),
                    height: 1,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: profile.heroImage.isEmpty
                    ? Image.asset(
                        _defaultHeroImage,
                        height: h * 0.88,
                        fit: BoxFit.contain,
                      )
                    : profile.heroImage.startsWith('assets/')
                    ? Image.asset(
                        profile.heroImage,
                        height: h * 0.88,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                              _defaultHeroImage,
                              height: h * 0.88,
                              fit: BoxFit.contain,
                            ),
                      )
                    : Image.network(
                        profile.heroImage,
                        height: h * 0.88,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                              _defaultHeroImage,
                              height: h * 0.88,
                              fit: BoxFit.contain,
                            ),
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
/// divided key-value table (born / age).
class _LeftPanel extends StatelessWidget {
  const _LeftPanel({required this.profile});

  final PlayerProfile profile;

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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                profile.name,
                style: const TextStyle(
                  fontFamily: 'Anton',
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  height: 0.98,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Icon(Icons.keyboard_arrow_down, size: 28, color: _ink),
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
            Expanded(
              child: Text(
                profile.club,
                style: const TextStyle(
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
              Expanded(
                child: _SpecTile(label: 'BOY', value: profile.height),
              ),
              const SizedBox(width: 24),
              Container(width: 1, color: _dividerColor),
              const SizedBox(width: 24),
              Expanded(
                child: _SpecTile(label: 'KİLO', value: profile.weight),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(height: 1, color: _dividerColor),
        _InfoRow(label: 'DOĞUM', value: profile.born),
        _InfoRow(label: 'YAŞ', value: profile.age, isLast: true),
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

/// Right-side card: real team/plan/status facts (takım, aktif plan,
/// diziliş, kaptanlık, uyruk, kart durumu) derived from the roster and the
/// active tactic - fills the space the original static demo used for a
/// fabricated match/video/career section.
class _TeamPanel extends StatelessWidget {
  const _TeamPanel({required this.profile});

  final PlayerProfile profile;

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
          const Text(
            'TAKIM VE PLAN',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < profile.teamFacts.length; i++)
            _InfoRow(
              label: profile.teamFacts[i].label,
              value: profile.teamFacts[i].value,
              isLast: i == profile.teamFacts.length - 1,
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
          const Positioned.fill(
            child: CustomPaint(painter: _TrendLinePainter()),
          ),
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
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Anton',
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
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
