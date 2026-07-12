import 'package:flutter/material.dart';
import '../../../../app_colors.dart';
import '../../widgets/settings_rows.dart';
import '../../widgets/settings_scaffold.dart';

class AiProviderScreen extends StatelessWidget {
  const AiProviderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'AI provider',
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        children: [
          const SettingsSectionLabel('Select provider'),
          SettingsGroup(
            children: [
              SettingsNavRow(
                iconWidget: SettingsIconCircle(
                  label: 'OR',
                  bgColor: AppColors.primary.withValues(alpha: 0.12),
                  color: AppColors.primary,
                ),
                title: 'OpenRouter',
                subtitle: 'Access 100+ models via one API',
                trailingWidget: const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                showChevron: false,
                onTap: () {},
              ),
              SettingsNavRow(
                iconWidget: SettingsIconCircle(
                  label: 'GQ',
                  bgColor: const Color(0xFFF55036).withValues(alpha: 0.12),
                  color: const Color(0xFFF55036),
                ),
                title: 'Groq',
                subtitle: 'Ultra-fast inference',
                showChevron: false,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
