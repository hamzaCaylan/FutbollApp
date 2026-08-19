import 'package:flutter/material.dart';

import '../models/app_page.dart';
import '../models/formation.dart';
import '../state/tactics_controller.dart';
import '../theme/app_colors.dart';

/// Curated photography from assets/dashboard/, used in place of the
/// pitch/jersey/ball art the rest of the app lets the coach pick in Ayarlar
/// - the dashboard is a fixed showcase, not something end users reskin.
class _DashboardArt {
  static const heroBackground = 'assets/dashboard/ds.jpg';
  static const continueCard = 'assets/dashboard/player.png';
  static const topPickCard = 'assets/dashboard/top2.jpg';
  static const activityCard = 'assets/dashboard/es.jpg';
  static const browseDizilis = 'assets/dashboard/top1.jpg';
  static const browseOyuncular = 'assets/dashboard/player.png';
  static const browseTaktikler = 'assets/dashboard/dash1.png';
  static const browseAyarlar = 'assets/dashboard/fm.jpg';
}

/// Wraps [builder]'s whole card in a single top-level [MouseRegion] and
/// hands back the hover-driven zoom scale to apply to the card's image.
/// The region has to be the outermost layer (not nested under sibling
/// paint layers inside the card's own Stack) - nesting it deeper left it
/// unable to receive hover events under CanvasKit.
class _HoverCard extends StatefulWidget {
  const _HoverCard({required this.builder});

  final Widget Function(BuildContext context, double imageScale) builder;

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: widget.builder(context, _hovering ? 1.08 : 1.0),
    );
  }
}

/// A card's background photo, pre-scaled by [scale] (driven by [_HoverCard]
/// above it) with a smooth animated transition.
class _ZoomImage extends StatelessWidget {
  const _ZoomImage({
    required this.imagePath,
    required this.scale,
    this.fit = BoxFit.cover,
  });

  final String imagePath;
  final double scale;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Image.asset(imagePath, fit: fit),
    );
  }
}

/// The dashboard's content area (right of the app's [Sidebar]) - matches the
/// reference streaming-service layout's shapes: a hero card and a light
/// "Browse" panel side by side at equal height, then a full-width row of
/// three secondary cards below both.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
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
        final squadCount = controller.players
            .where((p) => p.team == 'home')
            .length;
        final currentTactic = controller.tactics.firstWhere(
          (t) => t.id == controller.currentTacticId,
          orElse: () => controller.tactics.first,
        );

        final hero = _HeroCard(
          controller: controller,
          squadCount: squadCount,
          tacticName: currentTactic.name,
          onOpen: () => onSelectPage(AppPage.pitch),
        );
        final browse = _BrowsePanel(
          controller: controller,
          squadCount: squadCount,
          onSelectPage: onSelectPage,
        );
        final cards = _SecondaryCardsRow(
          controller: controller,
          squadCount: squadCount,
          onSelectPage: onSelectPage,
        );

        return Container(
          color: AppColors.dashboardBackground,
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              if (!wide) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 440, child: hero),
                      const SizedBox(height: 20),
                      browse,
                      const SizedBox(height: 20),
                      SizedBox(height: 300, child: cards),
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 440,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 3, child: hero),
                        const SizedBox(width: 20),
                        SizedBox(width: 300, child: browse),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(height: 300, child: cards),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _SecondaryCardsRow extends StatelessWidget {
  const _SecondaryCardsRow({
    required this.controller,
    required this.squadCount,
    required this.onSelectPage,
  });

  final TacticsController controller;
  final int squadCount;
  final ValueChanged<AppPage> onSelectPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ContinueCard(
            squadCount: squadCount,
            onOpen: () => onSelectPage(AppPage.players),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _TopPickCard(
            controller: controller,
            onOpen: () => onSelectPage(AppPage.pitch),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActivityCard(
            controller: controller,
            onOpen: () => onSelectPage(AppPage.settings),
          ),
        ),
      ],
    );
  }
}

/// The big "now streaming"-style hero: a full-bleed stadium photo behind
/// status badges, title, and a primary "İncele" action.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.controller,
    required this.squadCount,
    required this.tacticName,
    required this.onOpen,
  });

  final TacticsController controller;
  final int squadCount;
  final String tacticName;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      builder: (context, imageScale) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _ZoomImage(
              imagePath: _DashboardArt.heroBackground,
              scale: imageScale,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(0, -0.4),
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      const _Badge(
                        icon: Icons.circle,
                        iconSize: 8,
                        iconColor: Colors.greenAccent,
                        label: 'Aktif Plan',
                      ),
                      _Badge(label: '$squadCount oyuncu'),
                      _Badge(label: controller.homeFormation.label),
                      const _Badge(
                        icon: Icons.star,
                        iconColor: Colors.amber,
                        label: 'Öne Çıkan',
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    tacticName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      letterSpacing: 0.5,
                      shadows: [Shadow(blurRadius: 12, color: Colors.black87)],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onOpen,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'İncele',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (squadCount / 11).clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small translucent pill used for the hero's status badges.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    this.icon,
    this.iconColor = Colors.white,
    this.iconSize = 14,
  });

  final String label;
  final IconData? icon;
  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: iconColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared chrome for the three secondary cards: an image background, a dark
/// gradient, and a title pinned top-left - matching the reference's
/// Continue Watching / Top Pick / Now Playing card shape.
class _SecondaryCard extends StatelessWidget {
  const _SecondaryCard({
    required this.title,
    required this.imagePath,
    required this.child,
    this.imageFit = BoxFit.cover,
    this.topRight,
    this.onTap,
  });

  final String title;
  final String imagePath;
  final BoxFit imageFit;
  final Widget child;
  final Widget? topRight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      builder: (context, imageScale) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: AppColors.cardDark,
                  child: _ZoomImage(
                    imagePath: imagePath,
                    fit: imageFit,
                    scale: imageScale,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          ?topRight,
                        ],
                      ),
                      const Spacer(),
                      child,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small translucent circular icon button - the reference's carousel
/// prev/next arrows.
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.4),
      ),
      child: Icon(icon, size: 15, color: Colors.white),
    );
  }
}

/// A miniature switch matching the reference's watchlist/autoplay toggles.
class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.7,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: Colors.white38,
        inactiveThumbColor: Colors.white70,
        inactiveTrackColor: Colors.white24,
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.squadCount, required this.onOpen});

  final int squadCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final progress = (squadCount / 11).clamp(0.0, 1.0);
    return _SecondaryCard(
      title: 'Devam Eden Kadro',
      imagePath: _DashboardArt.continueCard,
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onOpen,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 18,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Devam Et',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$squadCount/11',
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopPickCard extends StatefulWidget {
  const _TopPickCard({required this.controller, required this.onOpen});

  final TacticsController controller;
  final VoidCallback onOpen;

  @override
  State<_TopPickCard> createState() => _TopPickCardState();
}

class _TopPickCardState extends State<_TopPickCard> {
  bool _favorite = false;

  @override
  Widget build(BuildContext context) {
    final formationLabel = widget.controller.homeFormation.label;
    return _SecondaryCard(
      title: 'Öne Çıkan',
      imagePath: _DashboardArt.topPickCard,
      imageFit: BoxFit.cover,
      onTap: widget.onOpen,
      topRight: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CircleIconButton(icon: Icons.chevron_left),
          const SizedBox(width: 6),
          _CircleIconButton(icon: Icons.chevron_right),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formationLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Diziliş · Önerilen',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          _MiniSwitch(
            value: _favorite,
            onChanged: (v) => setState(() => _favorite = v),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatefulWidget {
  const _ActivityCard({required this.controller, required this.onOpen});

  final TacticsController controller;
  final VoidCallback onOpen;

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  bool _autoplay = true;

  @override
  Widget build(BuildContext context) {
    return _SecondaryCard(
      title: 'Kayıtlı Planlar',
      imagePath: _DashboardArt.activityCard,
      onTap: widget.onOpen,
      topRight: _MiniSwitch(
        value: _autoplay,
        onChanged: (v) => setState(() => _autoplay = v),
      ),
      child: Row(
        children: [
          _CircleIconButton(icon: Icons.fast_rewind),
          const SizedBox(width: 8),
          InkWell(
            onTap: widget.onOpen,
            customBorder: const CircleBorder(),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(
                Icons.play_arrow,
                size: 20,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _CircleIconButton(icon: Icons.fast_forward),
          const Spacer(),
          Text(
            '${widget.controller.tactics.length} plan',
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// The light "Browse" shortcuts panel - one entry per app section, styled
/// to pop against the rest of the dark dashboard.
class _BrowsePanel extends StatelessWidget {
  const _BrowsePanel({
    required this.controller,
    required this.squadCount,
    required this.onSelectPage,
  });

  final TacticsController controller;
  final int squadCount;
  final ValueChanged<AppPage> onSelectPage;

  @override
  Widget build(BuildContext context) {
    final entries = [
      (
        image: _DashboardArt.browseDizilis,
        title: 'Diziliş',
        subtitle: '${controller.tactics.length} kayıtlı plan',
        page: AppPage.pitch,
      ),
      (
        image: _DashboardArt.browseOyuncular,
        title: 'Oyuncular',
        subtitle: '$squadCount kayıtlı oyuncu',
        page: AppPage.players,
      ),
      (
        image: _DashboardArt.browseTaktikler,
        title: 'Taktikler',
        subtitle: 'Çizim araçları',
        page: AppPage.pitch,
      ),
      (
        image: _DashboardArt.browseAyarlar,
        title: 'Ayarlar',
        subtitle: 'Görünüm ve tercihler',
        page: AppPage.settings,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightPanel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Browse',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < entries.length; i++) ...[
            _BrowseTile(
              image: entries[i].image,
              title: entries[i].title,
              subtitle: entries[i].subtitle,
              highlighted: i == 2,
              onTap: () => onSelectPage(entries[i].page),
            ),
            if (i != entries.length - 1) const SizedBox(height: 6),
          ],
          const Spacer(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => onSelectPage(AppPage.help),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'TÜMÜNÜ GÖR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowseTile extends StatelessWidget {
  const _BrowseTile({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.highlighted,
    required this.onTap,
  });

  final String image;
  final String title;
  final String subtitle;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      elevation: highlighted ? 1 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(radius: 20, backgroundImage: AssetImage(image)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.black.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
