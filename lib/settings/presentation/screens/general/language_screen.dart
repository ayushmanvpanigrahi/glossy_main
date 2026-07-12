import 'package:flutter/material.dart';
import '../../../../app_colors.dart';
import '../../widgets/settings_rows.dart';
import '../../widgets/settings_scaffold.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'English';

  static const _languages = [
    'English',
    'हिन्दी',
    'Español',
    'Français',
    'Deutsch',
    '中文',
    '日本語',
    'العربية',
  ];

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Language',
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        children: [
          const SettingsSectionLabel('App language'),
          SettingsGroup(
            children: _languages
                .map(
                  (lang) => SettingsNavRow(
                    iconWidget: const SettingsIconCircle(
                      label: '⇌',
                      icon: Icons.language_outlined,
                    ),
                    title: lang,
                    showChevron: false,
                    trailingWidget: _selected == lang
                        ? const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () => setState(() => _selected = lang),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
