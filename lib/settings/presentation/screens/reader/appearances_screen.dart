import 'package:flutter/material.dart';
import '../../../../app_colors.dart';
import '../../widgets/settings_rows.dart';
import '../../widgets/settings_scaffold.dart';

class AppearancesScreen extends StatefulWidget {
  const AppearancesScreen({super.key});

  @override
  State<AppearancesScreen> createState() => _AppearancesScreenState();
}

class _AppearancesScreenState extends State<AppearancesScreen> {
  String _fontSize = 'Medium';
  String _fontFamily = 'Inter';
  String _pageLayout = 'Single page';

  static const _fontSizes = ['Small', 'Medium', 'Large', 'X-Large'];
  static const _fontFamilies = [
    'Inter',
    'Playfair Display',
    'Merriweather',
    'Georgia',
  ];
  static const _layouts = ['Single page', 'Scroll', 'Two column'];

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Appearances',
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview',
                    style: TextStyle(
                      fontFamily: _fontFamily == 'Inter'
                          ? 'Inter'
                          : 'PlayfairDisplay',
                      fontSize: _fontSize == 'Small'
                          ? 13
                          : _fontSize == 'Large'
                          ? 18
                          : _fontSize == 'X-Large'
                          ? 22
                          : 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The quick brown fox jumps over the lazy dog. Reading is to the mind what exercise is to the body.',
                    style: TextStyle(
                      fontFamily: _fontFamily == 'Playfair Display'
                          ? 'PlayfairDisplay'
                          : 'Inter',
                      fontSize: _fontSize == 'Small'
                          ? 12
                          : _fontSize == 'Large'
                          ? 17
                          : _fontSize == 'X-Large'
                          ? 20
                          : 14,
                      color: AppColors.ink,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SettingsSectionLabel('Font size'),
          SettingsGroup(
            children: _fontSizes
                .map(
                  (size) => SettingsNavRow(
                    iconWidget: SettingsIconCircle(
                      label: size[0],
                      bgColor: _fontSize == size
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.secondary,
                      color: _fontSize == size
                          ? AppColors.primary
                          : AppColors.muted,
                    ),
                    title: size,
                    showChevron: false,
                    trailingWidget: _fontSize == size
                        ? const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () => setState(() => _fontSize = size),
                  ),
                )
                .toList(),
          ),
          const SettingsSectionLabel('Font'),
          SettingsGroup(
            children: _fontFamilies
                .map(
                  (font) => SettingsNavRow(
                    iconWidget: const SettingsIconCircle(
                      label: 'Aa',
                      icon: Icons.text_fields_rounded,
                    ),
                    title: font,
                    showChevron: false,
                    trailingWidget: _fontFamily == font
                        ? const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () => setState(() => _fontFamily = font),
                  ),
                )
                .toList(),
          ),
          const SettingsSectionLabel('Page layout'),
          SettingsGroup(
            children: _layouts
                .map(
                  (layout) => SettingsNavRow(
                    iconWidget: const SettingsIconCircle(
                      label: '≡',
                      icon: Icons.view_agenda_outlined,
                    ),
                    title: layout,
                    showChevron: false,
                    trailingWidget: _pageLayout == layout
                        ? const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () => setState(() => _pageLayout = layout),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
