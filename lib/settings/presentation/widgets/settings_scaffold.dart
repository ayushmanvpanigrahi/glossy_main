import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app_colors.dart';

// ---------------------------------------------------------------------------
// Shared scaffold for settings detail screens.
// ---------------------------------------------------------------------------

class SettingsDetailScaffold extends StatelessWidget {
  const SettingsDetailScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: AppColors.ink,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: AppColors.ink,
          ),
        ),
        actions: actions,
      ),
      body: body,
    );
  }
}

// ---------------------------------------------------------------------------
// Snackbar helper — matches the warm Glossy style.
// ---------------------------------------------------------------------------

void showSettingsSnackBar(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        msg,
        style: const TextStyle(
          fontFamily: 'Inter',
          color: AppColors.ink,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: AppColors.paper,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      elevation: 4,
      duration: const Duration(seconds: 3),
    ),
  );
}

// ---------------------------------------------------------------------------
// Listens to snackbar messages from the settings notifier.
// ---------------------------------------------------------------------------

class SettingsSnackbarListener extends StatefulWidget {
  const SettingsSnackbarListener({
    super.key,
    required this.message,
    required this.onShown,
    required this.child,
  });

  final String? message;
  final VoidCallback onShown;
  final Widget child;

  @override
  State<SettingsSnackbarListener> createState() =>
      _SettingsSnackbarListenerState();
}

class _SettingsSnackbarListenerState extends State<SettingsSnackbarListener> {
  @override
  void didUpdateWidget(SettingsSnackbarListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    final msg = widget.message;
    if (msg != null && msg != oldWidget.message) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showSettingsSnackBar(context, msg);
        widget.onShown();
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
