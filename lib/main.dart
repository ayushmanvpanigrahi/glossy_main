import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'library/home_screen.dart';
import 'settings/settings_screen.dart';

void main() => runApp(const GlossyApp());

class GlossyApp extends StatelessWidget {
  const GlossyApp({super.key});

  // ---------------------------------------------------------------------------
  // Theme helpers — pulled into private static helpers so build() stays lean.
  // ---------------------------------------------------------------------------

  static const _textTheme = TextTheme(
    headlineLarge: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: 32,
      fontWeight: FontWeight.bold,
      fontStyle: FontStyle.italic,
      color: AppColors.ink,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: 24,
      fontWeight: FontWeight.bold,
      fontStyle: FontStyle.italic,
      color: AppColors.ink,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'PlayfairDisplay',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.ink,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      color: AppColors.ink,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      color: AppColors.ink,
    ),
  );

  // Shared border-radius used by inputs and buttons.
  static final _radius8 = BorderRadius.circular(8);

  static ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.paper,
        secondary: AppColors.secondary,
        onSecondary: AppColors.ink,
        surface: AppColors.paper,
        onSurface: AppColors.ink,
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.paper,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(borderRadius: _radius8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.stage,
        border: OutlineInputBorder(
          borderRadius: _radius8,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _radius8,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      textTheme: _textTheme,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glossy',
      theme: _buildTheme(),
      home: const RootScreen(),
    );
  }
}

// ---------------------------------------------------------------------------

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;

  // Screens are const — Flutter will reuse the element without rebuilding.
  static const List<Widget> _screens = [
    HomeScreen(),
    SettingsScreen(),
  ];

  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Library'),
    BottomNavigationBarItem(icon: Icon(Icons.settings),  label: 'Settings'),
  ];

  void _onItemTapped(int index) {
    // Guard: skip setState if the user tapped the already-active tab.
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: _navItems,
      ),
    );
  }
}
