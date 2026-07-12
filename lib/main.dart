import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_colors.dart';
import 'router/app_router.dart';

void main() => runApp(const ProviderScope(child: GlossyApp()));

class GlossyApp extends ConsumerWidget {
  const GlossyApp({super.key});

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

  static final _radius8 = BorderRadius.circular(8);

  static ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      textTheme: _textTheme,
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
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Glossy',
      theme: _buildTheme(),
      routerConfig: router,
    );
  }
}
