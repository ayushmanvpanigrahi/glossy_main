import 'package:flutter/material.dart';
import '../../../../app_colors.dart';
import '../../widgets/settings_rows.dart';
import '../../widgets/settings_scaffold.dart';

class ReadingStatsScreen extends StatelessWidget {
  const ReadingStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Reading stats',
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _StatCard(label: 'Books read', value: '12'),
                const SizedBox(width: 10),
                _StatCard(label: 'Pages read', value: '1,482'),
                const SizedBox(width: 10),
                _StatCard(label: 'Day streak', value: '7 🔥'),
              ],
            ),
          ),
          const SettingsSectionLabel('This month'),
          SettingsGroup(
            children: [
              SettingsNavRow(
                iconWidget: const SettingsIconCircle(
                  label: '📚',
                  icon: Icons.book_outlined,
                ),
                title: 'Books finished',
                trailingText: '3',
                showChevron: false,
                onTap: null,
              ),
              SettingsNavRow(
                iconWidget: const SettingsIconCircle(
                  label: '⏱',
                  icon: Icons.timer_outlined,
                ),
                title: 'Reading time',
                trailingText: '14h 32m',
                showChevron: false,
                onTap: null,
              ),
              SettingsNavRow(
                iconWidget: const SettingsIconCircle(
                  label: '💬',
                  icon: Icons.chat_outlined,
                ),
                title: 'AI questions asked',
                trailingText: '48',
                showChevron: false,
                onTap: null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.stage,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
