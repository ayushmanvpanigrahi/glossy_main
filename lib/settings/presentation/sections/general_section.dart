import 'package:flutter/material.dart';
import '../widgets/settings_rows.dart';

class GeneralSection extends StatelessWidget {
  const GeneralSection({
    super.key,
    required this.notificationsEnabled,
    required this.language,
    required this.appVersion,
    required this.onNotificationsTap,
    required this.onLanguageTap,
    required this.onPrivacyTap,
    required this.onHelpTap,
  });

  final bool notificationsEnabled;
  final String language;
  final String appVersion;
  final VoidCallback onNotificationsTap;
  final VoidCallback onLanguageTap;
  final VoidCallback onPrivacyTap;
  final VoidCallback onHelpTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionLabel('General'),
        SettingsGroup(
          children: [
            SettingsNavRow(
              onTap: onNotificationsTap,
              iconWidget: const SettingsIconCircle(
                label: '♪',
                icon: Icons.notifications_outlined,
                iconSize: 17,
              ),
              title: 'Notifications',
              trailingText: notificationsEnabled ? 'On' : 'Off',
            ),
            SettingsNavRow(
              onTap: onLanguageTap,
              iconWidget: const SettingsIconCircle(
                label: '⇌',
                icon: Icons.language_outlined,
                iconSize: 17,
              ),
              title: 'Language',
              trailingText: language,
            ),
            SettingsNavRow(
              onTap: onPrivacyTap,
              iconWidget: const SettingsIconCircle(
                label: '∧',
                icon: Icons.shield_outlined,
              ),
              title: 'Privacy and data',
            ),
            SettingsNavRow(
              onTap: onHelpTap,
              iconWidget: const SettingsIconCircle(
                label: '?',
                icon: Icons.info_outline_rounded,
                iconSize: 17,
              ),
              title: 'Help and about',
              trailingText: appVersion,
            ),
          ],
        ),
      ],
    );
  }
}
