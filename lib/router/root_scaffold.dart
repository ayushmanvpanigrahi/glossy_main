import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Root shell — bottom navigation with IndexedStack via StatefulShellRoute.
// ---------------------------------------------------------------------------

class RootScaffold extends StatelessWidget {
  const RootScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Library'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
  ];

  void _onItemTapped(int index) {
    if (index == navigationShell.currentIndex) return;
    navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onItemTapped,
        items: _navItems,
      ),
    );
  }
}
