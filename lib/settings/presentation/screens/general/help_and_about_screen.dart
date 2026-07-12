import 'package:flutter/material.dart';
import '../../../../app_colors.dart';
import '../../providers/settings_state.dart';
import '../../widgets/settings_rows.dart';
import '../../widgets/settings_scaffold.dart';

class HelpAndAboutScreen extends StatelessWidget {
  const HelpAndAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Help and about',
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        children: [
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Glossy',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              SettingsState.appVersion,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const SettingsSectionLabel('Support'),
          SettingsGroup(
            children: [
              SettingsNavRow(
                iconWidget: const SettingsIconCircle(
                  label: '?',
                  icon: Icons.help_outline_rounded,
                ),
                title: 'FAQ',
                onTap: () {},
              ),
              SettingsNavRow(
                iconWidget: const SettingsIconCircle(
                  label: '✉',
                  icon: Icons.mail_outline_rounded,
                ),
                title: 'Contact support',
                onTap: () {},
              ),
              SettingsNavRow(
                iconWidget: const SettingsIconCircle(
                  label: '⭐',
                  icon: Icons.star_outline_rounded,
                ),
                title: 'Rate Glossy',
                onTap: () {},
              ),
            ],
          ),
          const SettingsSectionLabel('About'),
          SettingsGroup(
            children: [
              SettingsNavRow(
                iconWidget: const SettingsIconCircle(
                  label: 'v',
                  icon: Icons.update_outlined,
                ),
                title: 'Version',
                trailingText: SettingsState.appVersion,
                showChevron: false,
                onTap: null,
              ),
              SettingsNavRow(
                iconWidget: const SettingsIconCircle(
                  label: '📄',
                  icon: Icons.description_outlined,
                ),
                title: 'Open source licenses',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
