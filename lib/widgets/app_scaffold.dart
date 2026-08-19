import 'package:flutter/material.dart';

import '../models/app_page.dart';
import 'header.dart';
import 'sidebar.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key, required this.child});

  final Widget child;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final AppPage _selectedPage = AppPage.dashboard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: Header(
              title: 'FC Manager',
              showMenuIcon: !isWide,
              onMenuTap: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          drawer: isWide
              ? null
              : Drawer(
                  child: Sidebar(
                    selectedPage: _selectedPage,
                    onSelectPage: (page) {},
                  ),
                ),
          body: Row(
            children: [
              if (isWide)
                SizedBox(
                  width: 280,
                  child: Sidebar(
                    selectedPage: _selectedPage,
                    onSelectPage: (page) {},
                  ),
                ),
              Expanded(child: widget.child),
            ],
          ),
        );
      },
    );
  }
}
