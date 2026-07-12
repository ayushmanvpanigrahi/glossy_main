import 'package:flutter/material.dart';
import '../../../../app_colors.dart';
import '../../widgets/settings_rows.dart';
import '../../widgets/settings_scaffold.dart';

class PrivacyAndDataScreen extends StatelessWidget {
  const PrivacyAndDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Privacy and data',
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        children: [
          const SettingsSectionLabel('Your data'),
          SettingsGroup(
            children: [
              SettingsNavRow(
                iconWidget: const SettingsIconCircle(
                  label: '⬇',
                  icon: Icons.download_outlined,
                ),
                title: 'Export my data',
                subtitle: 'Download all your books and notes',
                onTap: () {},
              ),
              SettingsNavRow(
                iconWidget: SettingsIconCircle(
                  label: '🗑',
                  icon: Icons.delete_outline,
                  color: AppColors.danger,
                  bgColor: AppColors.danger.withValues(alpha: 0.10),
                ),
                title: 'Delete account',
                subtitle: 'Permanently remove all data',
                trailingText: '',
                showChevron: true,
                onTap: () {},
              ),
            ],
          ),
          const SettingsSectionLabel('Legal'),
          SettingsGroup(
            children: [
              SettingsNavRow(
                iconWidget: const SettingsIconCircle(
                  label: '📄',
                  icon: Icons.description_outlined,
                ),
                title: 'Privacy policy',
                onTap: () {},
              ),
              SettingsNavRow(
                iconWidget: const SettingsIconCircle(
                  label: '📋',
                  icon: Icons.article_outlined,
                ),
                title: 'Terms of service',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
