import 'package:flutter/material.dart';
import '../../widgets/settings_rows.dart';
import '../../widgets/settings_scaffold.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _readingReminders = true;
  bool _newFeatures = true;
  bool _weeklyDigest = false;

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Notifications',
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        children: [
          const SettingsSectionLabel('Notifications'),
          SettingsGroup(
            children: [
              SettingsToggleRow(
                iconWidget: const SettingsIconCircle(
                  label: '📖',
                  icon: Icons.auto_stories_outlined,
                ),
                title: 'Reading reminders',
                value: _readingReminders,
                onChanged: (v) => setState(() => _readingReminders = v),
              ),
              SettingsToggleRow(
                iconWidget: const SettingsIconCircle(
                  label: '✨',
                  icon: Icons.new_releases_outlined,
                ),
                title: 'New features',
                value: _newFeatures,
                onChanged: (v) => setState(() => _newFeatures = v),
              ),
              SettingsToggleRow(
                iconWidget: const SettingsIconCircle(
                  label: '📰',
                  icon: Icons.newspaper_outlined,
                ),
                title: 'Weekly digest',
                value: _weeklyDigest,
                onChanged: (v) => setState(() => _weeklyDigest = v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
