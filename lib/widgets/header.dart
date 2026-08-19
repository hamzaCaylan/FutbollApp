import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({
    super.key,
    required this.title,
    this.showMenuIcon = false,
    this.onMenuTap,
  });

  final String title;
  final bool showMenuIcon;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: false,
      elevation: 2,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      iconTheme: IconTheme.of(
        context,
      ).copyWith(color: Theme.of(context).colorScheme.primary),
      leading: showMenuIcon
          ? IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap)
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {},
          tooltip: 'About',
        ),
      ],
    );
  }
}
