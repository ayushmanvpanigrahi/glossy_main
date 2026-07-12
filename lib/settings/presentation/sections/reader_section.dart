import 'package:flutter/material.dart';
import '../widgets/settings_rows.dart';

class ReaderSection extends StatelessWidget {
  const ReaderSection({
    super.key,
    required this.fontSize,
    required this.darkMode,
    required this.onDarkModeChanged,
    required this.autoScroll,
    required this.onAutoScrollChanged,
    required this.pageLayout,
    required this.onAppearancesTap,
    required this.onPageLayoutTap,
  });

  final String fontSize;
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final bool autoScroll;
  final ValueChanged<bool> onAutoScrollChanged;
  final String pageLayout;
  final VoidCallback onAppearancesTap;
  final VoidCallback onPageLayoutTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionLabel('Reader'),
        SettingsGroup(
          children: [
            SettingsNavRow(
              onTap: onAppearancesTap,
              iconWidget: const SettingsIconCircle(label: 'T'),
              title: 'Font size',
              trailingText: fontSize,
            ),
            SettingsToggleRow(
              iconWidget: const SettingsIconCircle(
                label: '☽',
                icon: Icons.dark_mode_outlined,
              ),
              title: 'Dark mode',
              value: darkMode,
              onChanged: onDarkModeChanged,
            ),
            SettingsToggleRow(
              iconWidget: const SettingsIconCircle(
                label: '⇄',
                icon: Icons.swap_horiz_rounded,
                iconSize: 18,
              ),
              title: 'Auto-scroll',
              value: autoScroll,
              onChanged: onAutoScrollChanged,
            ),
            SettingsNavRow(
              onTap: onPageLayoutTap,
              iconWidget: const SettingsIconCircle(
                label: '≡',
                icon: Icons.view_agenda_outlined,
              ),
              title: 'Page layout',
              trailingText: pageLayout,
            ),
          ],
        ),
      ],
    );
  }
}
