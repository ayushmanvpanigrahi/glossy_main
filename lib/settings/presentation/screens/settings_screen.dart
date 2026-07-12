import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app_colors.dart';
import '../../../router/app_routes.dart';
import '../providers/settings_notifier.dart';
import '../providers/settings_state.dart';
import '../sections/account_section.dart';
import '../sections/ai_config_section.dart';
import '../sections/general_section.dart';
import '../sections/reader_section.dart';
import '../widgets/settings_rows.dart';
import '../widgets/settings_scaffold.dart';

// ---------------------------------------------------------------------------
// SettingsScreen — lean UI layer; state lives in SettingsNotifier.
// ---------------------------------------------------------------------------

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.secondary,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return SettingsSnackbarListener(
      message: state.snackbarMessage,
      onShown: notifier.clearSnackbar,
      child: Scaffold(
        backgroundColor: AppColors.secondary,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _SettingsHeader(
                  isSaving: state.isSaving,
                  onSave: notifier.save,
                ),
              ),
              SliverToBoxAdapter(
                child: AccountSection(
                  userName: SettingsState.userName,
                  userEmail: SettingsState.userEmail,
                  isPro: SettingsState.isPro,
                  onAccountTap: () =>
                      context.push(SettingsRoutes.path(SettingsRoutes.profile)),
                  onProTap: () =>
                      context.push(SettingsRoutes.path(SettingsRoutes.plan)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(
                child: AiConfigSection(
                  selectedModelId: state.selectedModelId,
                  orStatus: state.orStatus,
                  groqStatus: state.groqStatus,
                  onProviderTap: () => context.push(
                    SettingsRoutes.path(SettingsRoutes.aiProvider),
                  ),
                  onModelTap: () => context.push(
                    SettingsRoutes.path(SettingsRoutes.preferredModel),
                  ),
                  onApiKeysTap: () =>
                      context.push(SettingsRoutes.path(SettingsRoutes.apiKeys)),
                  onPromptTap: () => context.push(
                    SettingsRoutes.path(SettingsRoutes.customPrompt),
                  ),
                  onRagTap: () =>
                      context.push(SettingsRoutes.path(SettingsRoutes.rag)),
                  onHealthTap: () => context.push(
                    SettingsRoutes.path(SettingsRoutes.serviceHealth),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(
                child: ReaderSection(
                  fontSize: state.fontSize,
                  darkMode: state.darkMode,
                  onDarkModeChanged: notifier.setDarkMode,
                  autoScroll: state.autoScroll,
                  onAutoScrollChanged: notifier.setAutoScroll,
                  pageLayout: state.pageLayout,
                  onAppearancesTap: () => context.push(
                    SettingsRoutes.path(SettingsRoutes.appearances),
                  ),
                  onPageLayoutTap: () => context.push(
                    SettingsRoutes.path(SettingsRoutes.appearances),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(
                child: GeneralSection(
                  notificationsEnabled: state.notificationsEnabled,
                  language: state.language,
                  appVersion: SettingsState.appVersion,
                  onNotificationsTap: () => context.push(
                    SettingsRoutes.path(SettingsRoutes.notifications),
                  ),
                  onLanguageTap: () => context.push(
                    SettingsRoutes.path(SettingsRoutes.language),
                  ),
                  onPrivacyTap: () =>
                      context.push(SettingsRoutes.path(SettingsRoutes.privacy)),
                  onHelpTap: () =>
                      context.push(SettingsRoutes.path(SettingsRoutes.help)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(
                child: SignOutButton(
                  onTap: () => _showSignOutDialog(context, notifier),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign out?',
          style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 20),
        ),
        content: const Text(
          'Your settings will remain saved on this device.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.muted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Inter', color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.signOut();
            },
            child: const Text(
              'Sign out',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.isSaving, required this.onSave});

  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PREFERENCES',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppColors.muted,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Settings',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: isSaving ? null : onSave,
            child: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
